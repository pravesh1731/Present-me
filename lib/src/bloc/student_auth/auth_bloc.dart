import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/studentAuth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<FetchProfileRequested>(_onFetchProfileRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);

  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final t = repository.token;
      if (t == null) {
        emit(AuthUnauthenticated());
        return;
      }
      final profile = await repository.getProfile();
      emit(AuthAuthenticated(student: profile, token: t));
    } catch (e) {
      // token invalid or network issue -> unauthenticated
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final res = await repository.login(event.email, event.password);
      final token = res['token'] as String?;

      // Normalize user payload into Map<String, dynamic>
      Map<String, dynamic> userMap = {};
      final dynamic userRaw = res['student'];
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
          final profile = await repository.getProfile();
          userMap = Map<String, dynamic>.from(profile);
        } catch (_) {
          // ignore
        }
      }

      emit(AuthAuthenticated(student: userMap, token: token));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await repository.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onFetchProfileRequested(FetchProfileRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final profile = await repository.getProfile();
      emit(AuthAuthenticated(student: profile, token: repository.token));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfileRequested(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Apply patch. Prefer using the result returned by patchProfile(),
      // because some backends return the updated user in the PATCH response.
      // Only fall back to getProfile() when patchProfile doesn't return a Map.
      Map<String, dynamic>? patchedUser;
      try {
        final res = await repository.patchProfile(event.payload);
        patchedUser = Map<String, dynamic>.from(res);
      } catch (err) {
        debugPrint('patchProfile warning: $err');
        // continue to fallback
      }

      if (patchedUser == null) {
        // fallback: fetch canonical profile
        final refreshed = await repository.getProfile();
        emit(AuthAuthenticated(student: refreshed, token: repository.token));
      } else {
        emit(AuthAuthenticated(student: patchedUser, token: repository.token));
      }
    } catch (e, st) {
      debugPrint('AuthBloc._onUpdateProfileRequested failed: $e\n$st');
      emit(AuthFailure(message: e.toString()));
    }
  }

}
