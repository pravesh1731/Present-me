import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StudentRequestList extends StatelessWidget {
  final String classCode; // Pass this from the previous page

  const StudentRequestList({super.key, required this.classCode});

  @override
  Widget build(BuildContext context) {
    final classDoc = FirebaseFirestore.instance.collection('classes').doc(classCode);

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Requests', style: TextStyle(fontSize: 24, color: Colors.white)),
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: classDoc.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List requests = data['joinRequests'] ?? [];

          if (requests.isEmpty) {
            return Center(child: Text("No student requests yet."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final student = requests[index] as Map<String, dynamic>;

              final name = student['name']?.toString() ?? 'Unknown';
              final rollNo = student['rollNo']?.toString() ?? 'N/A';
              final photoUrl = student['photoUrl']?.toString() ?? '';


              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : AssetImage("assets/image/studnet.png") as ImageProvider,
                    radius: 25,
                  ),
                  title: Text(name, style: TextStyle(fontWeight: FontWeight.bold ,fontSize: 12)),
                  subtitle: Text('Roll No: $rollNo', style: TextStyle(fontSize: 10),),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await classDoc.update({
                            'students': FieldValue.arrayUnion([student['uid']]),
                            'joinRequests': FieldValue.arrayRemove([student]),
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Accept', style: TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                      SizedBox(width: 4),
                      Align(
                        child: ElevatedButton(
                          onPressed: () async {
                            await classDoc.update({
                              'joinRequests': FieldValue.arrayRemove([student]),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Reject', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ),
                    ],
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
