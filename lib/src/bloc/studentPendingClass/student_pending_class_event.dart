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


class StudentLeaveClass extends StudentPendingClassEvent {
  final String token;
  final String classCode;

  const StudentLeaveClass({
    required this.token,
    required this.classCode,
  });

  @override
  List<Object> get props => [token, classCode];
}
