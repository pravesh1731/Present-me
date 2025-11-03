import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:present_me_flutter/TeacherSendNoticeScreen.dart';

class Teachers_Notice_Class extends StatefulWidget {
  const Teachers_Notice_Class({super.key});

  @override
  State<Teachers_Notice_Class> createState() => _Teachers_Notice_ClassState();
}

class _Teachers_Notice_ClassState extends State<Teachers_Notice_Class> {
  @override
  String classCode = "code";
  final uid = FirebaseAuth.instance.currentUser?.uid;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Classes',
          style: TextStyle(fontSize: 24, color: Colors.white),
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('createdBy', isEqualTo: uid)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs.map((doc) {
                return {'name': doc['name'], 'code': doc['code']};
              }).toList();
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No classes found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Teacher_Send_Notice_Screen(className: snapshot.data![index]["name"],
                        classCode: snapshot.data![index]["code"],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Card(
                    elevation: 10,
                    shadowColor: Colors.greenAccent,
                    child: ListTile(
                      title: Text("${snapshot.data![index]["name"]}"),
                      subtitle: Text('Code: ${snapshot.data![index]['code']}'),
                      trailing: Icon(
                        Icons.arrow_forward,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
