part of 'teacher_class_bloc.dart';

sealed class TeacherClassEvent extends Equatable {
  const TeacherClassEvent();

  @override
  List<Object> get props => [];
}


class TeacherFetchClasses extends TeacherClassEvent {
  final String token;
  TeacherFetchClasses(this.token);
}
