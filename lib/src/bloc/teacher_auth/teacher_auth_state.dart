part of 'teacher_auth_bloc.dart';

sealed class TeacherAuthState extends Equatable {
  const TeacherAuthState();
  
  @override
  List<Object> get props => [];
}

final class TeacherAuthInitial extends TeacherAuthState {}

class TeacherAuthLoading extends TeacherAuthState {}

class TeacherPendingVerification extends TeacherAuthState {}

final class TeacherAuthAuthenticated extends TeacherAuthState {
  final Map<String, dynamic> teacher;
  final String? token;
  
  const TeacherAuthAuthenticated({required this.teacher, this.token});
  
  @override
  List<Object> get props => [teacher, token ?? ''];
}

final class TeacherAuthUnauthenticated extends TeacherAuthState {}

final class TeacherAuthFailure extends TeacherAuthState {
  final String message;
  
  const TeacherAuthFailure({required this.message});
  
  @override
  List<Object> get props => [message];
}