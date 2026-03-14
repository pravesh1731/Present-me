import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/constants/constants.dart';
import 'package:http/http.dart' as http;

class StudentRequestList extends StatefulWidget {
  final String classCode;
  final String className;

  const StudentRequestList({super.key, required this.classCode,  required this.className});

  @override
  State<StudentRequestList> createState() => _StudentRequestListState();
}

class _StudentRequestListState extends State<StudentRequestList> {

  List<_StudentJoinRequest> results = [];
  bool isLoading = true;


  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<List<_StudentJoinRequest>> getPendingStudentRequests(String token) async {
    final res = await http.get(
        Uri.parse('$baseUrl/teachers/class/${widget.classCode}/pendingStudentsList'),
      headers: _headers(token),
    );

    if (res.statusCode == 200) {

      final body = jsonDecode(res.body);

      final List data = body['students'] ?? [];


      return data.map((e) => _StudentJoinRequest(
        studentId: e['studentId'],
        firstName: e['firstName'],
        emailId: e['emailId'],
        rollNo: e['rollNo'],
        profilePicUrl: e['profilePicUrl'] ?? '',
        lastName: e['lastName'] ?? '',
      )).toList();

    } else {
      throw Exception(jsonDecode(res.body)['message']);
    }
  }

  Future<String> approveRejectRequest({
    required String classCode,
    required String studentId,
    required String action,
    required String token,
  }) async {

    final response = await http.patch(
      Uri.parse('$baseUrl/teachers/handle-student-request'),
      headers: _headers(token),
      body: json.encode({
        "classCode": classCode,
        "studentId": studentId,
        "action": action,
      }),
    );
    print(response.body);

    final data = json.decode(response.body);


    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ?? data['error'] ?? 'Failed to process request',
      );
    }

    return data['message'] ?? 'Request processed successfully';
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      String token = getToken();
      final result = await getPendingStudentRequests(token);

      setState(() {
        results = result;
        isLoading = false;
      });

    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = results.length;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context,  widget.className),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Pending Requests ($pendingCount)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
             else
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    "No student requests yet p.",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                ),
              )
            else
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                 itemCount: results.length,
                  itemBuilder: (context, index){
                   final student = results[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: const Border(
                          top: BorderSide(color: Color(0xFF10B981), width: 3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                student.profilePicUrl.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 22,
                                        backgroundImage: NetworkImage(student.profilePicUrl),
                                      )
                                    : CircleAvatar(
                                        radius: 22,
                                        backgroundColor: const Color(0xFF6366F1),
                                        child: Text(
                                          _getInitials(student.firstName),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(student.firstName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text('Roll No: ${student.rollNo}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      Text(student.firstName, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Request At: Just Now', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {

                                      try {
                                        final token = getToken();
                                        final message = await approveRejectRequest(
                                          classCode: widget.classCode,
                                          studentId: student.studentId,
                                          action: "approve",
                                          token: token,
                                        );
                                        setState(() {
                                          results.removeAt(index);   // removes student from UI list
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );

                                      }

                                    },
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Accept', style: TextStyle(fontSize: 15)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {

                                      try {

                                        final token = getToken();

                                        final message = await approveRejectRequest(
                                          classCode: widget.classCode,
                                          studentId: student.studentId,
                                          action: "reject",
                                          token: token,
                                        );

                                        setState(() {
                                          results.removeAt(index);   // removes student from UI list
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );

                                      } catch (e) {

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString())),
                                        );

                                      }

                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reject', style: TextStyle(fontSize: 15)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                  })
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String className) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 44, bottom: 24, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Requests',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            className.isNotEmpty ? 'Class: $className' : 'Class',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _StudentJoinRequest {
  final String studentId;
  final String firstName;
  final String lastName;
  final String emailId;
  final String rollNo;
  final String profilePicUrl;

  const _StudentJoinRequest({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.emailId,
    required this.rollNo,
    required this.profilePicUrl,

  });
}

