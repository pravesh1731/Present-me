part of 'teacher_class_bloc.dart';

sealed class TeacherClassState extends Equatable {
  const TeacherClassState();

  @override
  List<Object?> get props => [];
}

final class TeacherClassInitial extends TeacherClassState {}

final class TeacherClassLoading extends TeacherClassState {}

final class TeacherClassLoaded extends TeacherClassState {
  final List<ClassModel> classes;

  const TeacherClassLoaded(this.classes);

  @override
  List<Object?> get props => [classes];
}

final class TeacherClassError extends TeacherClassState {
  final String message;

  const TeacherClassError(this.message);

  @override
  List<Object?> get props => [message];
}
