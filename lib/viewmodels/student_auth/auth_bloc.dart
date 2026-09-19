import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
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
    on<ResendVerificationEmailRequested>(_onResendVerificationEmailRequested);
    on<VerifyEmailRequested>(_onVerifyEmailRequested);
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

  Future<void> _onLoginRequested(
      LoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final res = await repository.login(
        event.email,
        event.password,
      );

      debugPrint("LOGIN RESPONSE: $res");

      // =================================================
// EMAIL NOT VERIFIED
// =================================================

      if (res['emailNotVerified'] == true) {
        emit(
          EmailNotVerified(
            email: res['email']?.toString() ?? event.email,
            message: res['message']?.toString() ??
                'Email verification required',
          ),
        );

        return;
      }

// =================================================
// GET TOKEN
// =================================================

      final token = res['token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception("Token not received from server");
      }

      // =================================================
      // 2. GET STUDENT DATA
      // =================================================

      Map<String, dynamic> userMap = {};

      final dynamic userRaw = res['student'];

      if (userRaw is Map) {
        userMap = Map<String, dynamic>.from(userRaw);
      } else if (userRaw is String) {
        try {
          final decoded = jsonDecode(userRaw);

          if (decoded is Map) {
            userMap = Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          debugPrint("Student JSON decode error: $e");
        }
      }

      // =================================================
      // 3. IF STUDENT NOT IN LOGIN RESPONSE
      //    FETCH PROFILE
      // =================================================

      if (userMap.isEmpty) {
        try {
          final profile = await repository.getProfile();

          userMap = Map<String, dynamic>.from(profile);

          debugPrint("PROFILE RESPONSE: $userMap");
        } catch (e) {
          debugPrint("Profile fetch after login failed: $e");
        }
      }

      // =================================================
      // 4. CHECK STUDENT DATA
      // =================================================

      if (userMap.isEmpty) {
        throw Exception(
          "Student information was not received from server",
        );
      }

      // =================================================
      // 5. SAVE TOKEN + STUDENT
      // =================================================

      final box = GetStorage();

      await box.write('token', token);
      await box.write('student', userMap);
      await box.write('role', 'student');

      debugPrint("TOKEN SAVED: ${box.read('token')}");
      debugPrint("STUDENT SAVED: ${box.read('student')}");

      // =================================================
      // 6. AUTHENTICATED
      // =================================================

      emit(
        AuthAuthenticated(
          student: userMap,
          token: token,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        "LOGIN ERROR: $e\n$stackTrace",
      );

      emit(
        AuthFailure(
          message: e.toString(),
        ),
      );
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

  Future<void> _onResendVerificationEmailRequested(
      ResendVerificationEmailRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      await repository.resendVerificationEmail(event.email);

      emit(
        VerificationEmailResent(
          message: "Verification email sent successfully.",
        ),
      );
    } catch (e) {
      debugPrint(
        "Resend verification error: $e",
      );

      emit(
        AuthFailure(
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onVerifyEmailRequested(
      VerifyEmailRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      debugPrint("VERIFY EMAIL REQUESTED");
      debugPrint("TOKEN LENGTH: ${event.token.length}");

      final result = await repository.verifyEmail(event.token);

      debugPrint("VERIFY EMAIL RESULT: $result");

      emit(
        EmailVerificationSuccess(
          message: result['message']?.toString() ??
              'Email verified successfully.',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint(
        "VERIFY EMAIL ERROR: $e\n$stackTrace",
      );

      emit(
        EmailVerificationFailure(
          message: e.toString(),
        ),
      );
    }
  }
}
