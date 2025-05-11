import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreateClass extends StatefulWidget {
  @override
  State<CreateClass> createState() => _CreateClassState();
}

class _CreateClassState extends State<CreateClass> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method to create a new class
  void _showCreateClassDialog() {
    String className = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Class'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter class name'),
          onChanged: (value) => className = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (className.trim().isNotEmpty) {
                final code = (Random().nextInt(900000) + 100000).toString();
                final uid = _auth.currentUser?.uid;

                if (uid != null) {
                  final classData = {
                    'name': className.trim(),
                    'code': code,
                    'createdBy': uid,
                    'students': [], // Empty array initially
                    'createdAt': FieldValue.serverTimestamp(),
                  };

                  // Store the class in Firestore under classes collection
                  await _firestore.collection('classes').doc(code).set(classData);

                  Navigator.of(context).pop();
                }
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  // Stream to get all the classes of the logged-in teacher
  Stream<List<Map<String, dynamic>>> _getClassesStream() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return Stream.empty(); // If no user is logged in, return an empty stream

    // Query Firestore to get the classes created by the logged-in teacher
    return _firestore
        .collection('classes')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'code': doc['code'],
          'createdAt': doc['createdAt'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Class',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getClassesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading classes'));
            }

            final classes = snapshot.data ?? [];

            return Column(
              children: [
                // List of classes
                Expanded(
                  child: ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classItem = classes[index];
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Class info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classItem['name']!,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text('Class Code : ${classItem['code']}'),
                              ],
                            ),
                            // Action icons
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    TextEditingController _editController = TextEditingController(
                                      text: classItem['name'],
                                    );

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Edit Class Name"),
                                          content: TextField(
                                            controller: _editController,
                                            decoration: InputDecoration(hintText: "Enter new class name"),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Close dialog
                                              },
                                              child: Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final newName = _editController.text.trim();
                                                if (newName.isNotEmpty) {
                                                  // Update class name in Firestore
                                                  await _firestore
                                                      .collection('classes')
                                                      .doc(classItem['code'])
                                                      .update({'name': newName});

                                                  Navigator.of(context).pop(); // Close dialog
                                                }
                                              },
                                              child: Text("Save", style: TextStyle(color: Colors.blue)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Delete Class"),
                                          content: Text("Are you sure you want to delete this class?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Close dialog
                                              },
                                              child: Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                // Delete class from Firestore
                                                await _firestore
                                                    .collection('classes')
                                                    .doc(classItem['code'])
                                                    .delete();
                                                Navigator.of(context).pop(); // Close dialog after deleting
                                              },
                                              child: Text("Delete", style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy, color: Colors.black),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: classItem['code']!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Class code copied!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _showCreateClassDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
