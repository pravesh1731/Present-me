import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:present_me_flutter/src/repositories/teacherAuth_repository.dart';

part 'teacher_auth_event.dart';
part 'teacher_auth_state.dart';

class TeacherAuthBloc extends Bloc<TeacherAuthEvent, TeacherAuthState> {
  final TeacherAuthRepository t_repository;


  TeacherAuthBloc(this.t_repository) : super(TeacherAuthInitial()) {
    on<TeacherAuthEvent>(_onAppStarted);
    on<TeacherLoginRequested>(_onLoginRequested);
    on<TeacherLogoutRequested>(_onLogoutRequested);
    // on<TeacherFetchProfileRequested>(_onFetchProfileRequested);
  }

  Future<void> _onAppStarted(
    TeacherAuthEvent event,
    Emitter<TeacherAuthState> emit,
  ) async {
    emit(TeacherAuthLoading());
    try {
      final String? token = null; // Replace with actual token retrieval logic
      if (token == null) {
        emit(TeacherAuthUnauthenticated());
        return;
      }
      // Simulate fetching profile
      final profile = <String, dynamic>{
        'name': 'John Doe',
        'id': 1,
      }; // Replace with actual profile fetching logic
      emit(TeacherAuthAuthenticated(teacher: profile, token: token));
    } catch (e) {
      emit(TeacherAuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(TeacherLoginRequested event, Emitter<TeacherAuthState> emit) async {
    emit(TeacherAuthLoading());
    try {
      final res = await t_repository.teacherLogin(event.email, event.password);
      final token = res['token'] as String?;

      // Normalize user payload into Map<String, dynamic>
      Map<String, dynamic> userMap = {};
      final dynamic userRaw = res['teacher'];
      if (userRaw is Map) {
        userMap = Map<String, dynamic>.from(userRaw);
      } else if (userRaw is String) {
        try {
          final decoded = jsonDecode(userRaw);
          if (decoded is Map) userMap = Map<String, dynamic>.from(decoded);
        } catch (_) {
          // ignore
        }
      }

      // If we still don't have enough user data but we have a token, fetch profile
      if ((userMap.isEmpty || userMap.length < 3) && token != null) {
        try {
          final profile = await t_repository.getTeacherProfile();
          userMap = Map<String, dynamic>.from(profile);
        } catch (_) {
          // ignore
        }
      }

      emit(TeacherAuthAuthenticated(teacher: userMap, token: token));
    } catch (e) {
      emit(TeacherAuthFailure(message: e.toString()));
    }
  }


  Future<void> _onLogoutRequested(TeacherLogoutRequested event, Emitter<TeacherAuthState> emit) async {
    await t_repository.signOut();
    emit(TeacherAuthUnauthenticated());
  }

}
