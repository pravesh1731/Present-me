import 'dart:async';

import 'package:app/repositories/approveStudent_list.dart';
import 'package:app/repositories/notes_repository.dart';
import 'package:app/repositories/studentAuth_repository.dart';
import 'package:app/repositories/studentClass_repository.dart';
import 'package:app/repositories/studentPendingClass_repository.dart';
import 'package:app/repositories/student_attendance.dart';
import 'package:app/repositories/student_overall_attendance_repository.dart';
import 'package:app/repositories/teacherAuth_repository.dart';
import 'package:app/repositories/teacherClass_repository.dart';
import 'package:app/splash%20screen.dart';
import 'package:app/viewmodels/approveStudent_list/approveStudent_list_bloc.dart';
import 'package:app/viewmodels/notes/notes_bloc.dart';
import 'package:app/viewmodels/student_attendance/student_attendance_bloc.dart';
import 'package:app/viewmodels/student_auth/auth_bloc.dart';
import 'package:app/viewmodels/student_auth/auth_event.dart';
import 'package:app/viewmodels/student_auth/auth_state.dart';
import 'package:app/viewmodels/student_class/student_class_bloc.dart';
import 'package:app/viewmodels/student_overall_attendance/student_overall_attendance_bloc.dart';
import 'package:app/viewmodels/student_pending_class/student_pending_class_bloc.dart';
import 'package:app/viewmodels/teacher_auth/teacher_auth_bloc.dart';
import 'package:app/viewmodels/teacher_class/teacher_class_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final authRepository = AuthRepository();
  final teacherRepository = TeacherAuthRepository();
  final teacherClassRepository = TeacherClassRepository();
  final studentPendingClassRepository = StudentPendingClassRepository();
  final studentClassRepository = StudentClassRepository();
  final approveStudentListRepository = ApproveStudentRepository();
  final studentAttendanceRepository = StudentAttendanceRepository();
  final studentOverallAttendanceRepository = StudentOverallAttendanceRepository();
  final notesRepository = NotesRepository();

  runApp(

    ProviderScope(
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: authRepository),
          RepositoryProvider.value(value: teacherRepository),
          RepositoryProvider.value(value: teacherClassRepository),
          RepositoryProvider.value(value: studentPendingClassRepository),
          RepositoryProvider.value(value: studentClassRepository),
          RepositoryProvider.value(value: approveStudentListRepository),
          RepositoryProvider.value(value: studentAttendanceRepository),
          RepositoryProvider.value(value: studentOverallAttendanceRepository),
          RepositoryProvider.value(value: notesRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
              AuthBloc(repository: authRepository)..add(AppStarted()),
            ),
            BlocProvider(
              create: (_) =>
              TeacherAuthBloc(teacherRepository)..add(TeacherAppStarted()),
            ),
            BlocProvider(
              create: (_) => TeacherClassBloc(
                repository: teacherClassRepository,
              ),
            ),
            BlocProvider(
              create: (_) => StudentPendingClassBloc(
                repository: studentPendingClassRepository,
              ),
            ),
            BlocProvider(
              create: (_) => StudentClassBloc(
                repository: studentClassRepository,
              ),
            ),
            BlocProvider(
              create: (_) => ApproveStudentListBloc(
                repository: approveStudentListRepository,
              ),
            ),
            BlocProvider(
              create: (_) => StudentAttendanceBloc(
                repository: studentAttendanceRepository,
              ),
            ),
            BlocProvider(
              create: (_) => StudentOverallAttendanceBloc(
                repository: studentOverallAttendanceRepository,
              ),
            ),
            BlocProvider(
                create: (_) => NotesBloc(
                  repository: notesRepository,
                ),
              ),
          ],
          child: const ProviderScope(child: const MyApp()),
          )

        ),
      ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  // Prevent processing the same link twice
  String? _lastProcessedLink;

  // Navigator key so we can show UI from the deep-link handler
  final GlobalKey<NavigatorState> _navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  Future<void> _initDeepLinks() async {
    // =====================================================
    // APP OPENED FROM A CLOSED STATE
    // =====================================================

    try {
      final initialUri = await _appLinks.getInitialLink();

      if (initialUri != null) {
        debugPrint(
          "INITIAL APP LINK: $initialUri",
        );

        await _handleVerificationLink(initialUri);
      }
    } catch (e, stackTrace) {
      debugPrint(
        "Initial app link error: $e\n$stackTrace",
      );
    }

    // =====================================================
    // APP ALREADY RUNNING / BACKGROUND
    // =====================================================

    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        debugPrint(
          "RECEIVED APP LINK: $uri",
        );

        _handleVerificationLink(uri);
      },
      onError: (error) {
        debugPrint(
          "App link stream error: $error",
        );
      },
    );
  }

  Future<void> _handleVerificationLink(Uri uri) async {
    debugPrint("=================================");
    debugPrint("APP LINK RECEIVED");
    debugPrint("URI: $uri");
    debugPrint("SCHEME: ${uri.scheme}");
    debugPrint("HOST: ${uri.host}");
    debugPrint("PATH: ${uri.path}");
    debugPrint("QUERY: ${uri.queryParameters}");
    debugPrint("=================================");

    // =====================================================
    // PREVENT DUPLICATE PROCESSING
    // =====================================================

    final link = uri.toString();

    if (_lastProcessedLink == link) {
      debugPrint("Duplicate verification link ignored");
      return;
    }

    _lastProcessedLink = link;

    // =====================================================
    // CHECK DOMAIN
    // =====================================================

    if (uri.host != "presentme.in") {
      debugPrint("Not a Present-Me link");
      return;
    }

    // =====================================================
    // CHECK PATH
    // =====================================================

    if (uri.path != "/api/students/verify-email") {
      debugPrint(
        "Not an email verification link: ${uri.path}",
      );
      return;
    }

    // =====================================================
    // GET TOKEN
    // =====================================================

    final token = uri.queryParameters["token"];

    if (token == null || token.isEmpty) {
      debugPrint("Verification token missing");
      return;
    }

    debugPrint("VERIFICATION TOKEN RECEIVED");
    debugPrint("TOKEN LENGTH: ${token.length}");

    // =====================================================
    // SEND TOKEN TO AUTH BLOC
    // =====================================================

    if (!mounted) {
      return;
    }

    context.read<AuthBloc>().add(
      VerifyEmailRequested(
        token: token,
      ),
    );
  }

  void _showVerificationSuccess(String message) {
    final navigator = _navigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        "Navigator not ready. Verification succeeded: $message",
      );
      return;
    }

    final context = navigator.overlay?.context;

    if (context == null) {
      debugPrint(
        "Overlay context not available.",
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Email Verified",
          ),
          content: Text(
            message,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                "OK",
              ),
            ),
          ],
        );
      },
    );
  }

  void _showVerificationFailure(String message) {
    final navigator = _navigatorKey.currentState;

    if (navigator == null) {
      debugPrint(
        "Navigator not ready. Verification failed: $message",
      );
      return;
    }

    final context = navigator.overlay?.context;

    if (context == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Email Verification Failed",
          ),
          content: Text(
            message,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                "OK",
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // =================================================
        // VERIFICATION SUCCESS
        // =================================================

        if (state is EmailVerificationSuccess) {
          debugPrint(
            "EMAIL VERIFICATION SUCCESS: ${state.message}",
          );

          _showVerificationSuccess(
            state.message,
          );
        }

        // =================================================
        // VERIFICATION FAILURE
        // =================================================

        else if (state is EmailVerificationFailure) {
          debugPrint(
            "EMAIL VERIFICATION FAILURE: ${state.message}",
          );

          _showVerificationFailure(
            state.message,
          );
        }
      },
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Present Me',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ),
        ),
        home: splashScreen(),
      ),
    );
  }
}
