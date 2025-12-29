import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'student_pending_class_event.dart';
part 'student_pending_class_state.dart';

class StudentPendingClassBloc extends Bloc<StudentPendingClassEvent, StudentPendingClassState> {
  StudentPendingClassBloc() : super(StudentPendingClassInitial()) {
    on<StudentPendingClassEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
