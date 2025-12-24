part of 'teacher_auth_bloc.dart';

sealed class TeacherAuthEvent extends Equatable {
  const TeacherAuthEvent();

  @override
  List<Object> get props => [];
}
class TeacherAppStarted extends TeacherAuthEvent {}

class TeacherLoginRequested extends TeacherAuthEvent {
  final String email;
  final String password;

  const TeacherLoginRequested({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

class TeacherLogoutRequested extends TeacherAuthEvent {}

class TeacherFetchProfileRequested extends TeacherAuthEvent {}

class TeacherUpdateProfileRequested extends TeacherAuthEvent {
  final Map<String, dynamic> payload;

  const TeacherUpdateProfileRequested({required this.payload});
  @override
  List<Object> get props => [payload];
}


