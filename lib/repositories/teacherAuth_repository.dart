import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/constants.dart' as constants;

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
      // mark role as teacher and clear any student profile
      try {
        _storage.write('role', 'teacher');
        _storage.remove('student');
      } catch (_) {}
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

  Future<Map<String, dynamic>> patchTeacherProfile(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/teachers/profile');
    final t = token;
    if (t == null) throw Exception('No token available');
    final res = await _client.patch(uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $t'}, body: jsonEncode(payload));

    // Debug logging - help diagnose server responses that aren't maps
    try {
      debugPrint('patchProfile: status=${res.statusCode} body=${res.body}');
    } catch (_) {}

    dynamic decodedRaw;
    try {
      decodedRaw = jsonDecode(res.body);
    } catch (_) {
      decodedRaw = null;
    }


    final is2xx = res.statusCode >= 200 && res.statusCode < 300;
    final messageLooksLikeSuccess = decodedRaw is Map && decodedRaw['message'] is String && decodedRaw['message'].toString().toLowerCase().contains('success');

    // Treat as success if 2xx OR decoded message looks like success
    if (is2xx || messageLooksLikeSuccess) {
      // If server returned a map with `data`, use it; otherwise fetch profile to get canonical data
      if (decodedRaw is Map) {
        final result = (decodedRaw['data'] is Map) ? Map<String, dynamic>.from(decodedRaw['data']) : (decodedRaw['data'] ?? decodedRaw);
        // if result is a Map, persist and return it
        if (result is Map<String, dynamic>) {
          try {
            _storage.write('teacher', result);
          } catch (_) {}
          return result;
        }
      }

      // If decode didn't return an object with data, fetch canonical profile
      try {
        final profile = await getTeacherProfile();
        return profile;
      } catch (_) {
        // last-resort: if decodedRaw is a String message, return a map with message
        if (decodedRaw is String) return {'message': decodedRaw};
        throw Exception('Profile update failed');
      }
    }

    // Not successful
    if (decodedRaw is Map && decodedRaw['message'] != null) {
      final msg = decodedRaw['message'].toString();
      throw Exception(msg);
    }
    throw Exception('Profile update failed (status ${res.statusCode})');
  }


  /// Upload a profile picture using the same PATCH `/students/profile` API.
  /// Sends a multipart PATCH request with field name 'profilePicUrl'.
  /// Returns the updated profile map when available, or falls back to getProfile().
  Future<Map<String, dynamic>> uploadTeacherProfilePic(File file) async {
    final t = token;
    if (t == null) throw Exception('No token available');

    final uri = Uri.parse('$baseUrl/teachers/profile');
    final request = http.MultipartRequest('PATCH', uri);
    request.headers['Authorization'] = 'Bearer $t';

    // Use the server-expected field name 'profilePicUrl'
    final fieldName = 'profilePicUrl';
    try {
      final multipartFile = await http.MultipartFile.fromPath(fieldName, file.path);
      request.files.clear();
      request.files.add(multipartFile);
    } catch (e) {
      throw Exception('Failed to read file for upload: $e');
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    debugPrint('uploadProfilePic($fieldName): status=${res.statusCode}');
    debugPrint('uploadProfilePic($fieldName): body=${res.body}');

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = null;
    }

    final is2xx = res.statusCode >= 200 && res.statusCode < 300;
    if (is2xx) {
      if (decoded is Map) {
        final result = decoded['data'] ?? decoded;
        if (result is Map<String, dynamic>) {
          try {
            _storage.write('teacher', result);
          } catch (_) {}
          return Map<String, dynamic>.from(result);
        }
      }

      // fallback to GET profile when PATCH didn't return object
      try {
        final profile = await getTeacherProfile();
        return profile;
      } catch (e) {
        if (decoded is String) return {'message': decoded};
        throw Exception('Upload succeeded but failed to obtain profile: $e');
      }
    }

    if (decoded is Map && decoded['message'] != null) {
      throw Exception(decoded['message'].toString());
    }
    throw Exception('Upload failed (status ${res.statusCode})');
  }


  Future<void> signOut() async {
    // Clear all auth-related keys
    try {
      _storage.remove('token');
      _storage.remove('role');
      _storage.remove('teacher');
    } catch (_) {}
  }



  // create class api
  Future<Map<String, dynamic>> createClass({
    required String className,
    required String roomNo,
    required String startTime,
    required String endTime,
    required List classDays,

  }) async {
    final uri = Uri.parse('$baseUrl/teachers/class');
    final t = token;
    if (t == null) throw Exception('No token available');
    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: jsonEncode({
        'className': className,
        'roomNo': roomNo,
        'startTime': startTime,
        'endTime': endTime,
        'classDays': classDays,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body);
        throw Exception(body['message'] ?? 'Create class failed');
      } catch (_) {
        throw Exception('Create class failed with status ${res.statusCode}');
      }
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] ?? decoded;
    return {'data': data};
  }


}
