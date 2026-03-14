import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/studentClass.dart';

class StudentClassRepository {

  static const String baseUrl = 'https://presentme.in/api';

  // ================= HEADERS =================
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ================= GET ENROLLED CLASSES =================
  Future<List<StudentClassModel>> getEnrolledClasses(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/enrolledClasses'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['data'] ?? [];

      return list
          .map((e) => StudentClassModel.fromJson(e))
          .toList();
    } else {
      try {
        final decoded = json.decode(response.body);
        throw Exception(decoded['message'] ?? 'Failed to fetch classes');
      } catch (_) {
        throw Exception(
          'Failed to fetch classes (status ${response.statusCode})',
        );
      }
    }
  }

  // ================= JOIN CLASS =================
  /// ✅ Sends ONLY required fields
  Future<String> joinClass({
    required String classCode,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/students/joinRequests'),
      headers: _headers(token),
      body: json.encode({
        "classCode": classCode,
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? data['error'] ?? 'Failed to join class');
    }

    // ✅ RETURN MESSAGE FROM API
    return data['message'] ?? 'Join request sent';
  }




}

