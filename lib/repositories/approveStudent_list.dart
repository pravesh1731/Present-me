import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:present_me_flutter/core/constants/constants.dart';
import 'package:present_me_flutter/models/join_student_list.dart';

class ApproveStudentRepository {

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ================= GET ENROLLED CLASSES =================
  Future<List<JoinStudentList>> getJoinStudent(String token, String classCode) async {
    final res = await http.get(
      Uri.parse('$baseUrl/teachers/class/${classCode}/joinedStudentsList'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {

      final body = jsonDecode(res.body);
      final List data = body['students'] ?? [];

      return data.map((e) => JoinStudentList.fromJson(e)).toList();

    } else {
      throw Exception(jsonDecode(res.body)['message']);
    }
  }

}