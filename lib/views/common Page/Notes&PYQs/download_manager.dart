import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

// ═══════════════════════════════════════════════════════════
//  DOWNLOADED FILE MODEL
// ═══════════════════════════════════════════════════════════

class DownloadedNote {
  final String noteId;
  final String title;
  final String type;
  final String semester;
  final String department;
  final String teacher;
  final String localPath;
  final String downloadedAt;

  DownloadedNote({
    required this.noteId,
    required this.title,
    required this.type,
    required this.semester,
    required this.department,
    required this.teacher,
    required this.localPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'noteId':       noteId,
    'title':        title,
    'type':         type,
    'semester':     semester,
    'department':   department,
    'teacher':      teacher,
    'localPath':    localPath,
    'downloadedAt': downloadedAt,
  };

  factory DownloadedNote.fromJson(Map<String, dynamic> json) => DownloadedNote(
    noteId:       json['noteId'],
    title:        json['title'],
    type:         json['type'],
    semester:     json['semester'],
    department:   json['department'],
    teacher:      json['teacher'],
    localPath:    json['localPath'],
    downloadedAt: json['downloadedAt'],
  );
}

// ═══════════════════════════════════════════════════════════
//  DOWNLOAD MANAGER
// ═══════════════════════════════════════════════════════════

class DownloadManager {
  static const _storageKey = 'downloaded_notes';
  static final GetStorage _storage = GetStorage();
  // ── Private app directory (not accessible via file manager) ──
  static Future<Directory> _getNotesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory('${appDir.path}/downloaded_notes');
    if (!await notesDir.exists()) await notesDir.create(recursive: true);
    return notesDir;
  }

  // ── Generate a stable filename from URL ──
  static String _fileNameFromUrl(String url, String noteId) {
    final hash = md5.convert(utf8.encode(url)).toString().substring(0, 8);
    return 'note_${noteId}_$hash.pdf';
  }

  // ── Check if already downloaded ──
  static bool isDownloaded(String noteId) {
    final list = _getList();
    return list.any((n) => n.noteId == noteId);
  }

  // ── Get local path if downloaded ──
  static String? getLocalPath(String noteId) {
    final list = _getList();
    try {
      return list.firstWhere((n) => n.noteId == noteId).localPath;
    } catch (_) {
      return null;
    }
  }

  // ✅ Add this method to DownloadManager class
  static Future<void> _incrementDownloadCount(String noteId, String token) async {
    try {
      await http.patch(
        Uri.parse('https://presentme.in/api/students/notes/$noteId/download'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
    } catch (_) {
      // silent fail — don't block the user if counter fails
    }
  }

  // ── Download file and save to private storage ──
  static Future<DownloadedNote> download({
    required String noteId,
    required String title,
    required String type,
    required String semester,
    required String department,
    required String teacher,
    required String fileUrl,
    required String token,
    void Function(int received, int total)? onProgress,
  }) async {
    // Already downloaded → return cached
    if (isDownloaded(noteId)) {
      return _getList().firstWhere((n) => n.noteId == noteId);
    }

    final dir      = await _getNotesDir();
    final fileName = _fileNameFromUrl(fileUrl, noteId);
    final filePath = '${dir.path}/$fileName';

    // ✅ Download using http
    final response = await http.get(
      Uri.parse(fileUrl),
      // No headers needed for S3 public URLs
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download file (${response.statusCode})');
    }

    // ✅ Write bytes to private file
    await File(filePath).writeAsBytes(response.bodyBytes);
    await _incrementDownloadCount(noteId, token);

    final note = DownloadedNote(
      noteId:       noteId,
      title:        title,
      type:         type,
      semester:     semester,
      department:   department,
      teacher:      teacher,
      localPath:    filePath,
      downloadedAt: DateTime.now().toIso8601String(),
    );

    final list = _getList();
    list.add(note);
    _saveList(list);

    return note;
  }

  // ── Delete a downloaded note ──
  static Future<void> delete(String noteId) async {
    final list    = _getList();
    final note    = list.firstWhere((n) => n.noteId == noteId, orElse: () => throw Exception('Not found'));
    final file    = File(note.localPath);
    if (await file.exists()) await file.delete();
    list.removeWhere((n) => n.noteId == noteId);
    _saveList(list);
  }

  // ── Get all downloaded notes ──
  static List<DownloadedNote> getAllDownloaded() => _getList();

  // ── Internal helpers ──
  static List<DownloadedNote> _getList() {
    final raw = _storage.read<List>(_storageKey);
    if (raw == null) return [];
    return raw.map((e) => DownloadedNote.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static void _saveList(List<DownloadedNote> list) {
    _storage.write(_storageKey, list.map((e) => e.toJson()).toList());
  }
}
