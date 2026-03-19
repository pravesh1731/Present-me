import 'package:bloc/bloc.dart';
import 'package:present_me_flutter/repositories/approveStudent_list.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_event.dart';
import 'package:present_me_flutter/viewmodels/approveStudent_list/approveStudent_list_state.dart';


class ApproveStudentListBloc extends Bloc<ApproveStudentListEvent, ApproveStudentListState> {
  final  repository;

  ApproveStudentListBloc({required this.repository})
      : super(ApproveStudentListInitial()) {
    on<ApproveStudentFetchList>(_onFetchApproveStudentList);
  }


// ================= GET =================
  Future<void> _onFetchApproveStudentList(ApproveStudentFetchList event,
      Emitter<ApproveStudentListState> emit,) async {
    emit(ApproveStudentListLoading());
    try {
      final students = await repository.getJoinStudent(event.token, event.classCode);
      emit(ApproveStudentListLoaded(students));
    } catch (e) {
      emit(ApproveStudentListError(e.toString()));
    }
  }

}
