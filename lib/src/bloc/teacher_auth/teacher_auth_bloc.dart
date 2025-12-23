import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'teacher_auth_event.dart';
part 'teacher_auth_state.dart';

class TeacherAuthBloc extends Bloc<TeacherAuthEvent, TeacherAuthState> {
  TeacherAuthBloc() : super(TeacherAuthInitial()) {
    on<TeacherAuthEvent>(_onAppStarted);
    // on<TeacherLoginRequested>(_onLoginRequested);
    // on<TeacherLogoutRequested>(_onLogoutRequested);
    // on<TeacherFetchProfileRequested>(_onFetchProfileRequested);
  }

  Future<void> _onAppStarted(
    TeacherAuthEvent event,
    Emitter<TeacherAuthState> emit,
  ) async {
    emit(TeacherAuthLoading());
    try {
      final String? token = null; // Replace with actual token retrieval logic
      if (token == null) {
        emit(TeacherAuthUnauthenticated());
        return;
      }
      // Simulate fetching profile
      final profile = <String, dynamic>{
        'name': 'John Doe',
        'id': 1,
      }; // Replace with actual profile fetching logic
      emit(TeacherAuthAuthenticated(teacher: profile, token: token));
    } catch (e) {
      emit(TeacherAuthUnauthenticated());
    }
  }
}
