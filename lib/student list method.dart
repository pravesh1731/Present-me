import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:present_me_flutter/student%20request%20list.dart';

class studentListReq extends StatefulWidget {
  final String classCode;

  const studentListReq({required this.classCode});

  @override
  State<studentListReq> createState() => _studentListReqState();
}

class _studentListReqState extends State<studentListReq> {
  List<Map<String, dynamic>> studentsData = [];
  int _requestCount = 0;

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchRequestCount();
  }
  void _confirmRemoveStudent(int index) async {
    final studentName = studentsData[index]['name'];
    final studentId = await _getStudentIdByRoll(studentsData[index]['rollNo']);

    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Student ID not found.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Student'),
        content: Text('Are you sure you want to remove $studentName from the class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classCode)
                  .update({
                'students': FieldValue.arrayRemove([studentId])
              });

              setState(() {
                studentsData.removeAt(index);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$studentName has been removed.")),
              );
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<String?> _getStudentIdByRoll(String rollNo) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('roll', isEqualTo: rollNo)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }
    return null;
  }


  Future<void> fetchStudents() async {
    try {
      DocumentSnapshot classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .get();

      List<dynamic> studentIds = classDoc['students'];

      List<Map<String, dynamic>> tempData = [];

      for (String id in studentIds) {
        DocumentSnapshot studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(id)
            .get();

        if (studentDoc.exists) {
          tempData.add({
            'name': studentDoc['name'],
            'rollNo': studentDoc['roll'],
            'photoUrl': studentDoc['photoUrl'],
          });
        }
      }

      setState(() {
        studentsData = tempData;
      });
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  Future<void> fetchRequestCount() async {
    try {
      DocumentSnapshot classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .get();

      List<dynamic> requests = classDoc['joinRequests'] ?? [];
      setState(() {
        _requestCount = requests.length;
      });
    } catch (e) {
      print('Error fetching request count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  'Students',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ],
            ),

            Text(
              '[${studentsData.length}]', // Show student count
              style: TextStyle(fontSize: 20, color: Colors.yellow),
            ),
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentRequestList(classCode: widget.classCode),
                        ),
                      );
                    },
                    child: FaIcon(
                      Icons.message_outlined,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  if (_requestCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Center(
                          child: Text(
                            '$_requestCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          ],
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
      body: studentsData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: studentsData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding:
            const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: studentsData[index]['photoUrl'] != null &&
                      studentsData[index]['photoUrl']
                          .toString()
                          .isNotEmpty
                      ? NetworkImage(studentsData[index]['photoUrl'])
                      : AssetImage("assets/image/teacher.png")
                  as ImageProvider,
                ),
                title: Text(
                  studentsData[index]['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                Text('Roll No: ${studentsData[index]['rollNo']}'),
                trailing: PopupMenuButton<String>(
                  icon: FaIcon(Icons.more_vert_outlined),
                  onSelected: (value) {
                    if (value == 'remove') {
                      _confirmRemoveStudent(index);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('Remove'),
                    ),
                  ],
                ),

              ),
            ),
          );
        },
      ),
    );
  }
}
