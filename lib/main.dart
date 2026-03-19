
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/repositories/approveStudent_list.dart';
import 'package:present_me_flutter/repositories/studentAuth_repository.dart';
import 'package:present_me_flutter/repositories/studentClass_repository.dart';
import 'package:present_me_flutter/repositories/studentPendingClass_repository.dart';
import 'package:present_me_flutter/repositories/student_attendance.dart';
import 'package:present_me_flutter/repositories/teacherAuth_repository.dart';
import 'package:present_me_flutter/repositories/teacherClass_repository.dart';
import 'package:present_me_flutter/splash%20screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_bloc.dart';
import 'package:present_me_flutter/viewmodels/student_attendance/student_attendance_bloc.dart';
import 'package:present_me_flutter/viewmodels/student_auth/auth_bloc.dart';
import 'package:present_me_flutter/viewmodels/student_auth/auth_event.dart';
import 'package:present_me_flutter/viewmodels/student_class/student_class_bloc.dart';
import 'package:present_me_flutter/viewmodels/student_pending_class/student_pending_class_bloc.dart';
import 'package:present_me_flutter/viewmodels/teacher_auth/teacher_auth_bloc.dart';
import 'package:present_me_flutter/viewmodels/teacher_class/teacher_class_bloc.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Firebase.initializeApp();

  final authRepository = AuthRepository();
  final teacherRepository = TeacherAuthRepository();
  final teacherClassRepository = TeacherClassRepository();
  final studentPendingClassRepository = StudentPendingClassRepository();
  final studentClassRepository = StudentClassRepository();
  final approveStudentListRepository = ApproveStudentRepository();
  final studentAttendanceRepository = StudentAttendanceRepository();

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
          RepositoryProvider.value(value: studentAttendanceRepository)
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
          ],
          child: const MyApp(),
        ),
      ),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

 
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        title: 'Present Me',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: splashScreen(),
      );
  }
}
