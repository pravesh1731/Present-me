part of 'student_class_bloc.dart';

sealed class StudentClassState extends Equatable {
  const StudentClassState();

  @override
  List<Object> get props => [];
}

final class StudentClassInitial extends StudentClassState {}

final class StudentClassLoading extends StudentClassState {}

final class StudentClassLoaded extends StudentClassState {
  final List<StudentClassModel> classes;
  const StudentClassLoaded(this.classes);

  @override
  List<Object> get props => [classes];
}

final class StudentClassError extends StudentClassState {
  final String message;
  const StudentClassError(this.message);

  @override
  List<Object> get props => [message];
}


class StudentClassActionSuccess extends StudentClassState {
  final String message;

  const StudentClassActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}





