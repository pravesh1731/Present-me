import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class Teacher_Send_Notice_Screen extends StatefulWidget {
  final String className;
  final String classCode;

  const Teacher_Send_Notice_Screen({
    super.key,
    required this.className,
    required this.classCode,
  });

  @override
  State<Teacher_Send_Notice_Screen> createState() =>
      _Teacher_Send_Notice_ScreenState();
}

class _Teacher_Send_Notice_ScreenState extends State<Teacher_Send_Notice_Screen> {
  TextEditingController message = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isTeacher = false;
  int? editingIndex;
  String? editingDocId;
  List<Map<String, dynamic>> firestoreMessages = [];

  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    checkUserRole();
  }

  Future<void> checkUserRole() async {
    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode)
        .get();

    if (classDoc.exists) {
      final data = classDoc.data()!;
      setState(() {
        isTeacher = (data['createdBy'] == currentUserId);
      });
    }
  }
  Future<void> sendOrEditNotice() async {
    final text = message.text.trim();
    if (text.isEmpty) return;

    final classDoc = FirebaseFirestore.instance.collection('classes').doc(widget.classCode);
    final noticesCol = classDoc.collection('notices');

    if (editingDocId != null) {
      await noticesCol.doc(editingDocId).update({
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
        'sentBy': currentUserId,
      });
      setState(() {
        editingDocId = null;
        editingIndex = null;
        message.clear();
      });
    } else {
      await noticesCol.add({
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
        'sentBy': currentUserId,
      });

      
      await sendPushNotification(text);

      setState(() {
        message.clear();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  Future<void> sendPushNotification(String messageText) async {
    final tokensSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classCode)
        .collection('tokens')
        .get();

    for (var doc in tokensSnapshot.docs) {
      final token = doc['token'];
      await sendFCMNotification(token, messageText);
    }
  }

  Future<void> sendFCMNotification(String token, String messageText) async {
    const serverKey = 'AIzaSyC0YFpBPpYbnGcVFdpIdfg3UiqO4w4nLa8'; 

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': 'New Notice',
          'body': messageText,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'type': 'notice',
        }
      }),
    );
  }


  Future<void> deleteNotice(String docId) async {
    final classDoc = FirebaseFirestore.instance.collection('classes').doc(widget.classCode);
    final noticesCol = classDoc.collection('notices');

    await noticesCol.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notice', style: TextStyle(fontSize: 24, color: Colors.white)),
            Text(
              widget.className,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
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
          Padding(
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
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(widget.classCode)
                      .collection('notices')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No notices yet'));
                    }

                    firestoreMessages = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      return data;
                    }).toList();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: firestoreMessages.asMap().entries.map((entry) {
                          int index = entry.key;
                          Map<String, dynamic> msgData = entry.value;
                          String msg = msgData['message'] ?? '';
                          String docId = msgData['id'] ?? '';
                          String sentBy = msgData['sentBy'] ?? '';

                          return GestureDetector(
                            onLongPress: isTeacher
                                ? () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: const Text('Options'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.copy),
                                          title: const Text('Copy'),
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: msg));
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Copied to clipboard')),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.edit),
                                          title: const Text('Edit'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              message.text = msg;
                                              editingDocId = docId;
                                              editingIndex = index;
                                            });
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.delete),
                                          title: const Text('Delete'),
                                          onTap: () {
                                            Navigator.pop(context);
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Confirmation'),
                                                content: const Text('Are you sure you want to delete this message?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      Navigator.pop(context);
                                                      await deleteNotice(docId);
                                                    },
                                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF99ECFA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              if (isTeacher)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8, bottom: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: message,
                          decoration: InputDecoration(
                            hintText: "Type the Notice",
                            prefixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.camera_alt),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.attach_file),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final text = message.text.trim();
                          if (text.isNotEmpty) {
                            await sendOrEditNotice();
                            await sendPushNotification(text); 
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.blue,
                        ),
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
