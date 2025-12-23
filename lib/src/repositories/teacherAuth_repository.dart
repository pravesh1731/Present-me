import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:present_me_flutter/constants/constants.dart' as constants;

class TeacherAuthRepository {
  final http.Client _client;
  final GetStorage _storage;
  final String baseUrl;

  TeacherAuthRepository({
    http.Client? client,
    GetStorage? storage,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? GetStorage(),
       baseUrl = baseUrl ?? constants.baseUrl;

  String? get token => _storage.read<String>('token');

  Future<Map<String, dynamic>> signupTeacher({
    required String firstName,
    required String lastName,
    required String emailId,
    required String phone,
    required String hotspotName,
    required String institutionId,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/teachers/signup');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'emailId': emailId,
        'phone': phone,
        'hotspotName': hotspotName,
        'institutionId': institutionId,
        'password': password,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body);
        throw Exception(body['message'] ?? 'Signup failed');
      } catch (_) {
        throw Exception('Signup failed with status ${res.statusCode}');
      }
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] ?? decoded;
    return {'data': data};
  }
}
