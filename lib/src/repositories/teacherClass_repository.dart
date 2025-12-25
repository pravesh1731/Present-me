import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/src/models/class.dart';
import '../../constants/constants.dart' as constants;

class TeacherClassRepository {
  final http.Client _client;
  final GetStorage _storage;
  final String baseUrl;

  static const String _localKey = 'teacher_classes';

  TeacherClassRepository({
    http.Client? client,
    GetStorage? storage,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? GetStorage(),
        baseUrl = baseUrl ?? constants.baseUrl;


  // Return headers; omit Authorization when token is empty
  Map<String, String> _headers(String? token) {
    final map = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.trim().isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }


  /* =====================================================
     GET CLASSES (API + LOCAL CACHE)
     Robust: accepts array body or object with 'data'/'classes'
     ===================================================== */
  Future<List<ClassModel>> getClasses(String token) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/teachers/class'),
        headers: _headers(token),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);

        // normalize to List
        List list = [];
        if (body is List) {
          list = body;
        } else if (body is Map) {
          if (body['data'] is List) {
            list = body['data'];
          } else if (body['classes'] is List) {
            list = body['classes'];
          } else if (body['payload'] is List) {
            list = body['payload'];
          } else {
            // Try to find first List value in map
            final maybeList = body.values.firstWhere(
              (v) => v is List,
              orElse: () => [],
            );
            if (maybeList is List) list = maybeList;
          }
        }

        // map to models (guard against non-list)
        final classes = list.map<ClassModel?>((e) {
          try {
            if (e is Map) return ClassModel.fromJson(Map<String, dynamic>.from(e));
            if (e is String) {
              // attempt decode if stringified json
              try {
                final parsed = json.decode(e);
                if (parsed is Map) return ClassModel.fromJson(Map<String, dynamic>.from(parsed));
              } catch (_) {}
            }
          } catch (_) {}
          return null;
        }).whereType<ClassModel>().toList();

        // if parsed classes empty -> fallback to local cache instead of overwriting with empty
        if (classes.isNotEmpty) {
          _saveClassesLocally(classes);
          return classes;
        } else {
          // empty result, attempt return local cache
          final local = getLocalClasses();
          return local;
        }
      } else {
        // non-success -> fallback to local
        return getLocalClasses();
      }
    } catch (e) {
      // network / parse failure -> fallback to local storage
      return getLocalClasses();
    }
  }

  /* =====================================================
     CREATE CLASS
     ===================================================== */
  // Future<void> createClass(
  //     ClassModel classModel,
  //     String token,
  //     ) async {
  //   final response = await _client.post(
  //     Uri.parse('$baseUrl/teachers/class'),
  //     headers: _headers(token),
  //     body: json.encode(classModel.toJson()),
  //   );
  //
  //   if (response.statusCode != 201) {
  //     throw Exception('Failed to create class');
  //   }
  // }

  /* =====================================================
     UPDATE CLASS
     ===================================================== */
  // Future<void> updateClass(
  //     String classCode,
  //     ClassModel classModel,
  //     String token,
  //     ) async {
  //   final response = await _client.patch(
  //     Uri.parse('$baseUrl/teachers/class/$classCode'),
  //     headers: _headers(token),
  //     body: json.encode({
  //       'className': classModel.className,
  //       'roomNo': classModel.roomNo,
  //       'startTime': classModel.startTime,
  //       'endTime': classModel.endTime,
  //       'classDays': classModel.classDays,
  //     }),
  //   );
  //
  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to update class');
  //   }
  // }

  /* =====================================================
     DELETE CLASS
     ===================================================== */
  // Future<void> deleteClass(
  //     String classCode,
  //     String token,
  //     ) async {
  //   final response = await _client.delete(
  //     Uri.parse('$baseUrl/teachers/class/$classCode'),
  //     headers: _headers(token),
  //   );
  //
  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to delete class');
  //   }
  // }

  /* =====================================================
     LOCAL STORAGE (GetStorage)
     ===================================================== */
  void _saveClassesLocally(List<ClassModel> classes) {
    final data = classes.map((e) => e.toJson()).toList();
    _storage.write(_localKey, data);
  }

  List<ClassModel> getLocalClasses() {
    final data = _storage.read(_localKey);

    if (data == null) return [];

    try {
      return (data as List)
          .map(
            (e) => ClassModel.fromJson(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList();
    } catch (e) {
      return [];
    }
  }

  void clearLocalClasses() {
    _storage.remove(_localKey);
  }
}
