
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

  // ================= GET PENDING CLASSES =================
  Future<List<StudentPendingClassModel>> getPendingClasses(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/students/ViewJoinRequests'),
      headers: _headers(token),
    );

    final decoded = json.decode(response.body);

    //  SUCCESS
    if (response.statusCode == 200) {
      final List list = decoded['data'] ?? [];
      return list
          .map((e) => StudentPendingClassModel.fromJson(e))
          .toList();
    }

    //  NO DATA (NOT AN ERROR)
    if (response.statusCode == 404 &&
        decoded['message'] == 'No join requests found') {
      return []; // 👈 IMPORTANT
    }

    //  REAL ERROR
    throw Exception(decoded['message'] ?? 'Failed to fetch classes');
  }



  Future<String> leaveClass({
    required String token,
    required String classCode,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/students/leaveClass'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'classCode': classCode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['message']; //  API MESSAGE
    } else {
      throw Exception(data['message'] ?? 'Failed to leave class');
    }
  }



}

