import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:present_me_flutter/student%20Notiice%20main.dart';

class Student_Notice_classes extends StatefulWidget {
  const Student_Notice_classes({super.key});

  @override
  State<Student_Notice_classes> createState() => _Student_Notice_classesState();
}

class _Student_Notice_classesState extends State<Student_Notice_classes> {
  final currentUser = FirebaseAuth.instance.currentUser;


  @override
  void initState() {
    super.initState();

  }



  Stream<List<Map<String, dynamic>>> _getJoinedClassesStream() {
    return FirebaseFirestore.instance.collection('classes').snapshots().asyncMap(
          (snapshot) async {
        final userUid = currentUser?.uid;
        if (userUid == null) return [];

        final List<Map<String, dynamic>> userClasses = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final students = List<String>.from(data['students'] ?? []);
          if (students.contains(userUid)) {
            final title = data['name'] ?? 'Untitled Class';
            final code = doc.id;

            final noticeSnapshot = await FirebaseFirestore.instance
                .collection('classes')
                .doc(code)
                .collection('notices')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

            Timestamp? latestNotice;
            if (noticeSnapshot.docs.isNotEmpty) {
              latestNotice = noticeSnapshot.docs.first['timestamp'];
            }

            final lastSeenDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userUid)
                .collection('lastSeenNotices')
                .doc(code)
                .get();

            final lastSeen = lastSeenDoc.data()?['lastSeen'] as Timestamp?;

            final hasUnread = latestNotice != null &&
                (lastSeen == null || latestNotice.compareTo(lastSeen) > 0);

            userClasses.add({
              'name': title,
              'code': code,
              'hasUnread': hasUnread,
            });
          }
        }

        return userClasses;
      },
    );
  }

  void _navigateToClass(BuildContext context, String className, String classCode) async {
    final userUid = currentUser?.uid;
    if (userUid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('lastSeenNotices')
          .doc(classCode)
          .set({'lastSeen': Timestamp.now()});
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Student_Notice_Main(
          className: className,
          classCode: classCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Classes',
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getJoinedClassesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final classes = snapshot.data ?? [];

            if (classes.isEmpty) {
              return const Center(child: Text("You haven't joined any classes yet."));
            }

            return ListView.builder(
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classItem = classes[index];
                return InkWell(
                  onTap: () => _navigateToClass(context, classItem['name'], classItem['code']),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classItem['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class Code : ${classItem['code']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        classItem['hasUnread']
                            ? const Icon(Icons.circle, color: Colors.red, size: 14)
                            : const Icon(Icons.arrow_forward, color: Colors.blue, size: 28),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
