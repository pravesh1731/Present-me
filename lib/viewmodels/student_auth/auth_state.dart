import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> student;
  final String? token;
  AuthAuthenticated({required this.student, this.token});

  @override
  List<Object?> get props => [student, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}


class EmailNotVerified extends AuthState {
  final String email;
  final String message;

  EmailNotVerified({
    required this.email,
    required this.message,
  });

  @override
  List<Object?> get props => [email, message];
}

class VerificationEmailResent extends AuthState {
  final String message;

  VerificationEmailResent({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class EmailVerificationSuccess extends AuthState {
  final String message;

  EmailVerificationSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}

class EmailVerificationFailure extends AuthState {
  final String message;

  EmailVerificationFailure({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}