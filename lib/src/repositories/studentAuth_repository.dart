import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:present_me_flutter/constants/constants.dart' as constants;

/// Minimal AuthRepository to communicate with your existing API.
/// This avoids introducing strong models so you can migrate incrementally.
class AuthRepository {
  final http.Client _client;
  final GetStorage _storage;
  final String baseUrl;

  AuthRepository({http.Client? client, GetStorage? storage, String? baseUrl})
      : _client = client ?? http.Client(),
        _storage = storage ?? GetStorage(),
        baseUrl = baseUrl ?? constants.baseUrl;

  String? get token => _storage.read<String>('token');

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/students/login');
    final res = await _client.post(uri,
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

    final user = decodedMap['data'] ?? decodedMap['student'] ?? decodedMap['user'] ?? decodedMap;
    // persist minimal user map for quick access in UI
    try {
      _storage.write('student', user);
    } catch (_) {}

    return {
      'user': user,
      'token': decodedMap['token'],
    };
  }

  Future<Map<String, dynamic>> signupStudent({
    required String firstName,
    required String lastName,
    required String emailId,
    required String phone,
    required String institutionId,
    required String password,
    required String rollNo,
  }) async {
    final uri = Uri.parse('$baseUrl/students/signup');
    final res = await _client.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'emailId': emailId,
          'phone': phone,
          'institutionId': institutionId,
          'password': password,
          'rollNo': rollNo,
        }));

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


  Future<List<Map<String, dynamic>>> getColleges() async {
    final uri = Uri.parse('$baseUrl/getColleges');
    final res = await _client.get(uri);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to fetch colleges (status ${res.statusCode})');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = decoded['data'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final uri = Uri.parse('$baseUrl/students/profile');
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
          _storage.write('student', userRaw);
        } catch (_) {}
        return userRaw;
      }

      // unexpected shape
      throw Exception('Failed to fetch profile: unexpected data shape ${userRaw.runtimeType}');
    }
    throw Exception('Failed to fetch profile: invalid response');
  }

  Future<Map<String, dynamic>> patchProfile(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/students/profile');
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

    try {
      debugPrint('patchProfile: decodedRaw=${decodedRaw.runtimeType} -> ${decodedRaw}');
    } catch (_) {}

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
            _storage.write('student', result);
          } catch (_) {}
          return result;
        }
      }

      // If decode didn't return an object with data, fetch canonical profile
      try {
        final profile = await getProfile();
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
      debugPrint('patchProfile failing with message: $msg');
      throw Exception(msg);
    }
    debugPrint('patchProfile: unknown failure, status=${res.statusCode}');
    throw Exception('Profile update failed (status ${res.statusCode})');
  }


  /// Upload a profile picture using the same PATCH `/students/profile` API.
  /// Sends a multipart PATCH request with field name 'profilePicUrl'.
  /// Returns the updated profile map when available, or falls back to getProfile().
  Future<Map<String, dynamic>> uploadProfilePic(File file) async {
    final t = token;
    if (t == null) throw Exception('No token available');

    final uri = Uri.parse('$baseUrl/students/profile');
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
            _storage.write('student', result);
          } catch (_) {}
          return Map<String, dynamic>.from(result);
        }
      }

      // fallback to GET profile when PATCH didn't return object
      try {
        final profile = await getProfile();
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
    _storage.remove('token');
  }
}
