import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentRequestList extends StatelessWidget {
  final String classCode;

  const StudentRequestList({super.key, required this.classCode});

  @override
  Widget build(BuildContext context) {
    final classDoc = FirebaseFirestore.instance.collection('classes').doc(classCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF1FCF8),
      body: StreamBuilder<DocumentSnapshot>(
        stream: classDoc.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, '', ''),

                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List requests = data['joinRequests'] ?? [];
          final className = data['name'] ?? '';
          final grade = data['grade'] ?? '';
          final pendingCount = requests.length;
          ;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, className, grade),
                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Pending Requests ($pendingCount)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 10),
                if (requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text("No student requests yet.", style: TextStyle(fontSize: 15, color: Colors.black54))),
                  )
                else
                  ...requests.map((student) {
                    final name = student['name']?.toString() ?? 'Unknown';
                    final email = student['email']?.toString() ?? '';
                    final rollNo = student['rollNo']?.toString() ?? 'N/A';
                    final photoUrl = student['photoUrl']?.toString() ?? '';
                    final requestedAt = student['requestedAt'] != null
                        ? DateFormat('yMMMd').add_jm().format((student['requestedAt'] as Timestamp).toDate())
                        : 'Requested just now';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border(
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
                                photoUrl.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 22,
                                        backgroundImage: NetworkImage(photoUrl),
                                      )
                                    : CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Color(0xFF6366F1),
                                        child: Text(
                                          _getInitials(name),
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
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text('Roll No: $rollNo', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      Text(email, style: const TextStyle(fontSize: 13, color: Colors.black54)),
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
                                Text(requestedAt, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await classDoc.update({
                                        'students': FieldValue.arrayUnion([student['uid']]),
                                        'joinRequests': FieldValue.arrayRemove([student]),
                                        'processedRequests': FieldValue.arrayUnion([student]),
                                      });
                                    },
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Accept', style: TextStyle(fontSize: 15)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF10B981),
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
                                      await classDoc.update({
                                        'joinRequests': FieldValue.arrayRemove([student]),
                                        'processedRequests': FieldValue.arrayUnion([student]),
                                      });
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Reject', style: TextStyle(fontSize: 15)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFEF4444),
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
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String className, String grade) {
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
                            className.isNotEmpty ? className : 'Class',
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
