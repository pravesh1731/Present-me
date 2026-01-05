
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/splash%20screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:present_me_flutter/src/bloc/studentClass/student_class_bloc.dart';
import 'package:present_me_flutter/src/bloc/studentPendingClass/student_pending_class_bloc.dart';
import 'package:present_me_flutter/src/bloc/teacherClass/teacher_class_bloc.dart';
import 'package:present_me_flutter/src/repositories/studentClass_repository.dart';
import 'package:present_me_flutter/src/repositories/studentPendingClass_repository.dart';
import 'package:present_me_flutter/src/repositories/teacherClass_repository.dart';
import 'src/repositories/studentAuth_repository.dart';
import 'src/repositories/teacherAuth_repository.dart';
import 'src/bloc/student_auth/auth_bloc.dart';
import 'src/bloc/student_auth/auth_event.dart';
import 'src/bloc/teacher_auth/teacher_auth_bloc.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Firebase.initializeApp();

  final authRepository = AuthRepository();
  final teacherRepository = TeacherAuthRepository();
  final teacherClassRepository = TeacherClassRepository();
  final studentPendingClassRepository = StudentPendingClassRepository();
  final studentClassRepository = StudentClassRepository();

  runApp(
    ProviderScope(
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: authRepository),
          RepositoryProvider.value(value: teacherRepository),
          RepositoryProvider.value(value: teacherClassRepository),
          RepositoryProvider.value(value: studentPendingClassRepository),
          RepositoryProvider.value(value: studentClassRepository),
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
