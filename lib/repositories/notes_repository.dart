// repositories/notes_repository.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants/constants.dart';
import '../models/note_upload_model.dart';

class NotesRepository {


  Future<NoteUploadResponse> uploadNote({
    required String token,
    required String type,          // 'Notes' | 'PYQ'
    required String semester,
    required String year,
    required String course,
    required String department,
    String? teacherName,           // required only for Notes
    required File file,
    required String fileName,
    required String mimeType,
  }) async {
    final uri = Uri.parse('$baseUrl/students/notes/upload');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['type']           = type
      ..fields['semester']       = semester
      ..fields['year']           = year
      ..fields['course']         = course
      ..fields['department']     = department;

    if (type == 'Notes' && teacherName != null) {
      request.fields['teacherName'] = teacherName;
    }

    // ✅ Attach file
    request.files.add(await http.MultipartFile.fromPath(
      'file',        // must match multer field name
      file.path,
      filename:    fileName,
      contentType: MediaType.parse(mimeType),
    ));

    final streamedResponse = await request.send();
    final response         = await http.Response.fromStream(streamedResponse);
    final decoded          = json.decode(response.body);

    if (response.statusCode == 201) {
      return NoteUploadResponse.fromJson(decoded);
    }
  if (response.statusCode == 409) {
  throw _DuplicateException(decoded['message'] ?? 'File already exists');
  }

    throw Exception(decoded['message'] ?? 'Upload failed (${response.statusCode})');
  }


  Future<Map<String, dynamic>> fetchNotes({
    required String token,
    required String course,
    required String department,
    required String semester,
    required String type,
  }) async {

    final uri = Uri.parse('$baseUrl/students/notes').replace(
      queryParameters: {
        'course': course,
        'department': department,
        'semester': semester,
        'type': type,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to fetch notes');
    }
  }
}




class _DuplicateException implements Exception {
  final String message;
  _DuplicateException(this.message);
  @override
  String toString() => message;
}

