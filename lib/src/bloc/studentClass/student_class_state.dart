part of 'student_class_bloc.dart';

sealed class StudentClassState extends Equatable {
  const StudentClassState();
  
  @override
  List<Object> get props => [];
}

final class StudentClassInitial extends StudentClassState {}
