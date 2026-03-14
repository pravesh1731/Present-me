import 'package:equatable/equatable.dart';
import 'package:present_me_flutter/models/join_student_list.dart';

sealed class ApproveStudentListState extends Equatable {
  const ApproveStudentListState();

  @override
  List<Object?> get props => [];
}

final class ApproveStudentListInitial extends ApproveStudentListState {}

final class ApproveStudentListLoading extends ApproveStudentListState {}

final class ApproveStudentListLoaded extends ApproveStudentListState {
  final List<JoinStudentList> students;
  const ApproveStudentListLoaded(this.students);

  @override
  List<Object?> get props => [students];
}

final class ApproveStudentListError extends ApproveStudentListState {
  final String message;
  const ApproveStudentListError(this.message);

  @override
  List<Object?> get props => [message];
}