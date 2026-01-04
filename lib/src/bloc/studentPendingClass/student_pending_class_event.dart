part of 'student_pending_class_bloc.dart';

sealed class StudentPendingClassEvent extends Equatable {
  const StudentPendingClassEvent();

  @override
  List<Object> get props => [];
}

// FETCH PENDING CLASSES
class StudentFetchPendingClasses extends StudentPendingClassEvent {
  final String token;

  const StudentFetchPendingClasses(this.token);

  @override
  List<Object> get props => [token];
}