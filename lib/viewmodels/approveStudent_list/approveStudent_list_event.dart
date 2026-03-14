import 'package:equatable/equatable.dart';

sealed class ApproveStudentListEvent extends Equatable {
  const ApproveStudentListEvent();

  @override
  List<Object?> get props => [];
}

// ================= FETCH =================
class ApproveStudentFetchList extends ApproveStudentListEvent {
  final String token;
  final String classCode;
  const ApproveStudentFetchList(this.token, this.classCode);

  @override
  List<Object?> get props => [token, classCode];
}