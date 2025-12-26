import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/class.dart';

class TeacherClassRepository {
  /// ✅ YOUR REAL BASE URL
  static const String baseUrl = 'https://presentme.in/api';

  // ================= HEADERS =================
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ================= GET CLASSES =================
  Future<List<ClassModel>> getClasses(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/teachers/class'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);
        List rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded['data'] is List) rawList = decoded['data'];
          else if (decoded['classes'] is List) rawList = decoded['classes'];
          else if (decoded['results'] is List) rawList = decoded['results'];
          else if (decoded['items'] is List) rawList = decoded['items'];
          else {
            // fallback: find first list in values
            final first = decoded.values.firstWhere((v) => v is List, orElse: () => null);
            if (first is List) rawList = first;
          }
        }

        if (rawList.isEmpty) {
          // nothing found, return empty list
          return <ClassModel>[];
        }

        return rawList.map((e) {
          if (e is Map<String, dynamic>) return ClassModel.fromJson(e);
          if (e is Map) return ClassModel.fromJson(Map<String, dynamic>.from(e));
          return ClassModel.fromJson(Map<String, dynamic>.from(e as Map));
        }).toList();
      } catch (e) {
        print('[TeacherClassRepository] getClasses parse error: $e');
        return <ClassModel>[];
      }
    } else {
      try {
        final decoded = json.decode(response.body);
        throw Exception(decoded['message'] ?? 'Failed to fetch classes');
      } catch (_) {
        throw Exception('Failed to fetch classes (status ${response.statusCode})');
      }
    }
  }

  // ================= CREATE CLASS =================
  /// ✅ Sends ONLY required fields
  Future<void> createClass({
    required String token,
    required String className,
    required String roomNo,
    required String startTime, // HH:mm
    required String endTime,   // HH:mm
    required List<String> classDays,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teachers/class'),
      headers: _headers(token),
      body: json.encode({
        "className": className,
        "roomNo": roomNo,
        "startTime": startTime,
        "endTime": endTime,
        "classDays": classDays,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        json.decode(response.body)['message'] ?? 'Failed to create class',
      );
    }
  }

  // ================= UPDATE CLASS =================
  Future<void> updateClass({
    required String token,
    required String classCode,
    required String className,
    required String roomNo,
    required String startTime,
    required String endTime,
    required List<String> classDays,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/teachers/class/$classCode'),
      headers: _headers(token),
      body: json.encode({
        "className": className,
        "roomNo": roomNo,
        "startTime": startTime,
        "endTime": endTime,
        "classDays": classDays,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        json.decode(response.body)['message'] ?? 'Failed to update class',
      );
    }
  }

  // ================= DELETE CLASS =================
  Future<void> deleteClass({
    required String token,
    required String classCode,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/teachers/class/$classCode'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        json.decode(response.body)['message'] ?? 'Failed to delete class',
      );
    }
  }
}
