part of 'student_pending_class_bloc.dart';

sealed class StudentPendingClassState extends Equatable {
  const StudentPendingClassState();
  
  @override
  List<Object> get props => [];
}

final class StudentPendingClassInitial extends StudentPendingClassState {}

final class StudentPendingClassLoading extends StudentPendingClassState {}

final class StudentPendingClassLoaded extends StudentPendingClassState  {
  final List<StudentPendingClassModel> classes;
  const StudentPendingClassLoaded(this.classes);

  @override
  List<Object> get props => [classes];
}

final class StudentPendingClassError extends StudentPendingClassState  {
  final String message;
  const StudentPendingClassError(this.message);

  @override
  List<Object> get props => [message];
}