import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import 'main.dart';

class Student_Notice_Main extends StatefulWidget {
  final String className;
  final String classCode;

  const Student_Notice_Main({
    super.key,
    required this.className,
    required this.classCode,
  });

  @override
  State<Student_Notice_Main> createState() => _Student_Notice_MainState();
}



class _Student_Notice_MainState extends State<Student_Notice_Main> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    saveStudentToken(widget.classCode);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'notice_channel',
              'Notice Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

  }

  void saveStudentToken(String classCode) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await FirebaseMessaging.instance.getToken();

    if (user != null && token != null) {
      final tokenDoc = FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('tokens')
          .doc(user.uid);

      await tokenDoc.set({
        'token': token,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }


  Future<bool> _isStudentEnrolled() async {
    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode)
        .get();

    if (classDoc.exists) {
      final data = classDoc.data()!;
      final List<dynamic> students = data['students'] ?? [];
      return students.contains(currentUser?.uid);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isStudentEnrolled(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        if (snapshot.data == false) {
          return Scaffold(
            appBar: AppBar(title: Text('Access Denied')),
            body: const Center(child: Text("You are not enrolled in this class.")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notice', style: TextStyle(fontSize: 22, color: Colors.white)),
                Text(widget.className, style: const TextStyle(fontSize: 16, color: Colors.white)),
              ],
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
          body: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100.0, left: 10, right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Opacity(
                      opacity: 0.25,
                      child: Image.asset(
                        "assets/image/noticebg.jpg",
                        alignment: Alignment.center,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.classCode)
                    .collection('notices')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notices = snapshot.data!.docs;

                  if (notices.isEmpty) {
                    return const Center(child: Text("No notices yet."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 16, left: 12, right: 12, bottom: 100),
                    itemCount: notices.length,
                    itemBuilder: (context, index) {
                      final data = notices[index].data() as Map<String, dynamic>;
                      final message = data['message'] ?? '';
                      final timestamp = data['timestamp'] as Timestamp?;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xff99ECFA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (timestamp != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${DateFormat('dd-MM-yyyy').format(timestamp.toDate())} at ${DateFormat('HH:mm').format(timestamp.toDate())}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),

                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
