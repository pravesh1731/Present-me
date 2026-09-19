import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

class FetchProfileRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final Map<String, dynamic> payload;
  UpdateProfileRequested({required this.payload});

  @override
  List<Object?> get props => [payload];
}

class ResendVerificationEmailRequested extends AuthEvent {
  final String email;

  ResendVerificationEmailRequested({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}
class VerifyEmailRequested extends AuthEvent {
  final String token;

  VerifyEmailRequested({
    required this.token,
  });

  @override
  List<Object?> get props => [token];
}


