// models/note_upload_model.dart
class NoteUploadResponse {
  final String message;
  final String noteId;
  final String fileUrl;
  final String status;

  const NoteUploadResponse({
    required this.message,
    required this.noteId,
    required this.fileUrl,
    required this.status,
  });

  factory NoteUploadResponse.fromJson(Map<String, dynamic> json) {
    return NoteUploadResponse(
      message: json['message'] ?? '',
      noteId:  json['noteId']  ?? '',
      fileUrl: json['fileUrl'] ?? '',
      status:  json['status']  ?? '',
    );
  }
}