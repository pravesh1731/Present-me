part of 'student_pending_class_bloc.dart';

sealed class StudentPendingClassState extends Equatable {
  const StudentPendingClassState();
  
  @override
  List<Object> get props => [];
}

final class StudentPendingClassInitial extends StudentPendingClassState {}
