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


  Future<Map<String, dynamic>> teacherLogin(String email, String password) async {
    final uri = Uri.parse('$baseUrl/teachers/login');
    final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emailId': email, 'password': password}));

    Map<String, dynamic>? decoded;
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      decoded = null;
    }

    final is2xx = res.statusCode >= 200 && res.statusCode < 300;
    final messageLooksLikeSuccess = decoded != null && decoded['message'] is String && decoded['message'].toString().toLowerCase().contains('success');

    // Treat as error only when not 2xx and message doesn't look like success
    if (!is2xx && !messageLooksLikeSuccess) {
      try {
        final body = decoded ?? jsonDecode(res.body);
        throw Exception(body['message'] ?? 'Login failed');
      } catch (_) {
        throw Exception('Login failed Try again');
      }
    }

    final decodedMap = decoded ?? (res.body.isNotEmpty ? {'message': res.body} : <String, dynamic>{});
    // attempt to pick token & user
    if (decodedMap['token'] != null) {
      _storage.write('token', decodedMap['token']);
    }

    final teacher = decodedMap['data'] ?? decodedMap['teacher'] ?? decodedMap['user'] ?? decodedMap;
    // persist minimal user map for quick access in UI
    try {
      _storage.write('teacher',teacher);
    } catch (_) {}

    return {
      'teacher': teacher,
      'token': decodedMap['token'],
    };
  }

  Future<Map<String, dynamic>> getTeacherProfile() async {
    final uri = Uri.parse('$baseUrl/teachers/profile');
    final t = token;
    if (t == null) throw Exception('No token available');
    final res = await _client.get(uri, headers: {'Authorization': 'Bearer $t'});
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      dynamic userRaw = decoded['data'] ?? decoded;
      // If server put JSON as a string in 'data', attempt to decode it
      if (userRaw is String) {
        try {
          final maybe = jsonDecode(userRaw);
          if (maybe is Map<String, dynamic>) userRaw = maybe;
        } catch (_) {
          // leave as string
        }
      }

      if (userRaw is Map<String, dynamic>) {
        try {
          _storage.write('teacher', userRaw);
        } catch (_) {}
        return userRaw;
      }

      // unexpected shape
      throw Exception('Failed to fetch profile: unexpected data shape ${userRaw.runtimeType}');
    }
    throw Exception('Failed to fetch profile: invalid response');
  }

  Future<void> signOut() async {
    _storage.remove('token');
  }
}
