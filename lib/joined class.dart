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

    final classDoc = FirebaseFirestore.instance.collection('classes').doc(code);

    try {
      final snapshot = await classDoc.get();
      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Class code not found")),
        );
        return;
      }

      final data = snapshot.data()!;
      final List<dynamic> students = data['students'] ?? [];

      if (students.contains(currentUser!.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You have already joined this class")),
        );
      } else {
        await classDoc.update({
          'students': FieldValue.arrayUnion([currentUser!.uid]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Joined class successfully")),
        );
      }

      Navigator.of(context).pop(); // Close dialog
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
