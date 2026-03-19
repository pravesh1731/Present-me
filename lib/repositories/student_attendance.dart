import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/student_attendance_model.dart';
import '../components/common/Button/token.dart';
import '../core/constants/constants.dart';

class StudentAttendanceRepository {

  /// GET STUDENT ATTENDANCE
  Future<StudentAttendanceResponse> getStudentAttendance({
    required String classCode,
    required String studentId,
  }) async {

    final token = getToken();

    final url =
        "$baseUrl/teachers/student-attendance/$classCode/$studentId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    /// ERROR HANDLING
    if (response.statusCode != 200) {
      throw Exception(
        data["message"] ?? "Failed to fetch student attendance",
      );
    }

    /// SUCCESS
    return StudentAttendanceResponse.fromJson(data);
  }
}