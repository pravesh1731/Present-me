import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student_overall_attendance_model.dart';

class StudentOverallAttendanceRepository {
  static const String baseUrl = 'https://presentme.in/api';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<StudentOverallAttendance> getOverallAttendance(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/attendance-overall'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return StudentOverallAttendance.fromJson(decoded);
    } else {
      try {
        final decoded = json.decode(response.body);
        throw Exception(decoded['message'] ?? 'Failed to fetch overall attendance');
      } catch (_) {
        throw Exception('Failed to fetch overall attendance (status ${response.statusCode})');
      }
    }
  }
}