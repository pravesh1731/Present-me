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
import 'package:app/viewmodels/student_class/student_class_bloc.dart';
import 'package:app/viewmodels/student_overall_attendance/student_overall_attendance_bloc.dart';
import 'package:app/viewmodels/student_pending_class/student_pending_class_bloc.dart';
import 'package:app/viewmodels/teacher_auth/teacher_auth_bloc.dart';
import 'package:app/viewmodels/teacher_class/teacher_class_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';




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
