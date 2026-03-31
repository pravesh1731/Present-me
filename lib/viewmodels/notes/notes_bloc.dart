import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/notes_repository.dart';
import '../../views/common Page/Notes&PYQs/Notes&PYQ.dart';
import 'notes_event.dart';
import 'notes_state.dart';


class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesRepository repository;

  NotesBloc({required this.repository}) : super(NotesInitial()) {

    // ✅ Upload
    on<UploadNote>(_onUpload);

    // ✅ Fetch (NEW)
    on<FetchNotes>(_onFetchNotes);
    on<FetchMyUploads>(_onFetchMyUploads);
  }

  // ═══════════════════════════════════════════════════════
  //  UPLOAD
  // ═══════════════════════════════════════════════════════

  Future<void> _onUpload(
      UploadNote event,
      Emitter<NotesState> emit,
      ) async {
    emit(NotesUploading());

    try {
      final response = await repository.uploadNote(
        token:       event.token,
        type:        event.type,
        semester:    event.semester,
        year:        event.year,
        course:      event.course,
        department:  event.department,
        teacherName: event.teacherName,
        file:        event.file,
        fileName:    event.fileName,
        mimeType:    event.mimeType,
      );

      emit(NotesUploadSuccess(response));

    } on _DuplicateException catch (e) {
      emit(NotesUploadError(e.message, isDuplicate: true));
    } catch (e) {
      emit(NotesUploadError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  // ═══════════════════════════════════════════════════════
  //  FETCH NOTES (NEW)
  // ═══════════════════════════════════════════════════════

  Future<void> _onFetchNotes(
      FetchNotes event,
      Emitter<NotesState> emit,
      ) async {
    emit(NotesLoading());

    try {
      final response = await repository.fetchNotes(
        token: event.token,
        course: event.course,
        department: event.department,
        semester: event.semester,
        type: event.type,
      );

      // ✅ IMPORTANT PART (YOUR LINE FIXED)
      final notes = (response['data'] as List)
          .map((e) => NoteModel.fromJson(e))
          .toList();

      emit(NotesFetchSuccess(notes));

    } catch (e) {
      emit(NotesFetchError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }


  Future<void> _onFetchMyUploads(
      FetchMyUploads event,
      Emitter<NotesState> emit,
      ) async {
    emit(MyUploadsLoading());
    try {
      final notes = await repository.fetchMyUploads(token: event.token);
      emit(MyUploadsFetchSuccess(notes));
    } catch (e) {
      emit(MyUploadsFetchError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}

class _DuplicateException implements Exception { final String message; _DuplicateException(this.message); @override String toString() => message; }