// viewmodels/notes/notes_event.dart
import 'dart:io';

abstract class NotesEvent {}

class UploadNote extends NotesEvent {
  final String token;
  final String type;
  final String semester;
  final String year;
  final String course;
  final String department;
  final String? teacherName;
  final File file;
  final String fileName;
  final String mimeType;

  UploadNote({
    required this.token,
    required this.type,
    required this.semester,
    required this.year,
    required this.course,
    required this.department,
    this.teacherName,
    required this.file,
    required this.fileName,
    required this.mimeType,
  });
}

class FetchNotes extends NotesEvent {
  final String token;
  final String course;
  final String department;
  final String semester;
  final String type;

  FetchNotes({
    required this.token,
    required this.course,
    required this.department,
    required this.semester,
    required this.type,
  });
}