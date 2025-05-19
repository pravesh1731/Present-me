import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class joined_Class extends StatefulWidget {
  @override
  State<joined_Class> createState() => _joined_ClassState();
}

class _joined_ClassState extends State<joined_Class> {
  final TextEditingController _codeController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  void _joinClass(String code) async {
    if (currentUser == null) return;

    final classDocRef = FirebaseFirestore.instance.collection('classes').doc(code);

    try {
      final classSnapshot = await classDocRef.get();

      if (!classSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Class code not found")),
        );
        return;
      }

      final classData = classSnapshot.data()!;
      final userId = currentUser!.uid;

      // Check if already joined
      final List<dynamic> joinedStudents = classData['students'] ?? [];
      if (joinedStudents.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You have already joined this class")),
        );
        return;
      }

      // Check if already requested
      final List<dynamic> joinRequests = classData['joinRequests'] ?? [];
      final alreadyRequested = joinRequests.any((req) => req['uid'] == userId);
      if (alreadyRequested) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You have already requested to join this class")),
        );
        return;
      }

      // Get student info
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .get();

      final studentData = {
        'uid': userId,
        'name': studentSnapshot['name'] ?? '',
        'rollNo': studentSnapshot['roll'] ?? '',
        'photoUrl': studentSnapshot['photoUrl'] ?? '',
      };

      // Add request
      await classDocRef.update({
        'joinRequests': FieldValue.arrayUnion([studentData]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request sent. Wait for teacher approval.")),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }



  void _showJoinClassDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Join Class"),
          content: TextField(
            controller: _codeController,
            decoration: InputDecoration(hintText: "Enter class code"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _codeController.clear();
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _joinClass(_codeController.text.trim());
                _codeController.clear();
              },
              child: Text("Join"),
            ),
          ],
        );
      },
    );
  }

  Stream<List<Map<String, String>>> _getJoinedClassesStream() {
    return FirebaseFirestore.instance.collection('classes').snapshots().map((snapshot) {
      final userUid = currentUser?.uid;
      if (userUid == null) return [];

      final List<Map<String, String>> userClasses = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final students = List<String>.from(data['students'] ?? []);
        if (students.contains(userUid)) {
          final title = data['name'] ?? 'Untitled Class';
          final code = doc.id;
          userClasses.add({'title': title, 'code': code});
        }
      }

      return userClasses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Joined Class', style: TextStyle(fontSize: 24, color: Colors.white)),
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
      body: StreamBuilder<List<Map<String, String>>>(
        stream: _getJoinedClassesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return Center(child: Text("You haven't joined any classes yet."));
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final classItem = classes[index];
              return Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(classItem['title']!, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Class Code: ${classItem['code']}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _showJoinClassDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
