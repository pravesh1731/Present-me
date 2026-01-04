
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:present_me_flutter/src/models/studentClass.dart';
import 'package:present_me_flutter/src/models/studentPendingClass.dart';

class StudentPendingClassRepository {

  static const String baseUrl = 'https://presentme.in/api';

  // ================= HEADERS =================
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ================= GET ENROLLED CLASSES =================
  Future<List<StudentPendingClassModel>> getPendingClasses(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/ViewJoinRequests'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List list = decoded['data'] ?? [];

      return list
          .map((e) => StudentPendingClassModel.fromJson(e))
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


}

