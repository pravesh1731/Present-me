// viewmodels/notes/notes_state.dart
import '../../models/note_upload_model.dart';
import '../../views/common Page/Notes&PYQ.dart';

abstract class NotesState {}

class NotesInitial   extends NotesState {}
class NotesUploading extends NotesState {}

class NotesUploadSuccess extends NotesState {
  final NoteUploadResponse data;
  NotesUploadSuccess(this.data);
}

class NotesUploadError extends NotesState {
  final String message;
  final bool isDuplicate; // ✅ add this

  NotesUploadError(this.message, {this.isDuplicate = false});
}

class NotesLoading extends NotesState {}

class NotesFetchSuccess extends NotesState {
  final List<NoteModel> notes;

  NotesFetchSuccess(this.notes);
}

class NotesFetchError extends NotesState {
  final String message;

  NotesFetchError(this.message);
}

