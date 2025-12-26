part of 'teacher_class_bloc.dart';

sealed class TeacherClassEvent extends Equatable {
  const TeacherClassEvent();

  @override
  List<Object?> get props => [];
}

// ================= FETCH =================
class TeacherFetchClasses extends TeacherClassEvent {
  final String token;
  const TeacherFetchClasses(this.token);

  @override
  List<Object?> get props => [token];
}

// ================= CREATE =================
class TeacherCreateClass extends TeacherClassEvent {
  final String token;
  final String className;
  final String roomNo;
  final String startTime; // HH:mm
  final String endTime;   // HH:mm
  final List<String> classDays;

  const TeacherCreateClass({
    required this.token,
    required this.className,
    required this.roomNo,
    required this.startTime,
    required this.endTime,
    required this.classDays,
  });

  @override
  List<Object?> get props =>
      [token, className, roomNo, startTime, endTime, classDays];
}

// ================= UPDATE =================
class TeacherUpdateClass extends TeacherClassEvent {
  final String token;
  final String classCode;
  final String className;
  final String roomNo;
  final String startTime;
  final String endTime;
  final List<String> classDays;

  const TeacherUpdateClass({
    required this.token,
    required this.classCode,
    required this.className,
    required this.roomNo,
    required this.startTime,
    required this.endTime,
    required this.classDays,
  });

  @override
  List<Object?> get props =>
      [token, classCode, className, roomNo, startTime, endTime, classDays];
}

// ================= DELETE =================
class TeacherDeleteClass extends TeacherClassEvent {
  final String token;
  final String classCode;

  const TeacherDeleteClass({
    required this.token,
    required this.classCode,
  });

  @override
  List<Object?> get props => [token, classCode];
}
