part of 'student_class_bloc.dart';

sealed class StudentClassEvent extends Equatable {
  const StudentClassEvent();

  @override
  List<Object> get props => [];
}

        // FETCH ENROLLED CLASSES
class StudentFetchEnrolledClasses extends StudentClassEvent {
  final String token;

  const StudentFetchEnrolledClasses(this.token);

  @override
  List<Object> get props => [token];
}


// ================= JOIN =================
class StudentJoinClass extends StudentClassEvent {
  final String token;
  final String classCode;


  const StudentJoinClass({
    required this.token,
    required this.classCode,
  });

  @override
  List<Object> get props => [token, classCode];

}

