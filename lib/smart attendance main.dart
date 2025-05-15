import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:present_me_flutter/button.dart';

class SmartAttendanceTeacherPage extends StatefulWidget {
  final String className;
  final String classCode;

  SmartAttendanceTeacherPage({required this.className, required this.classCode});

  @override
  _SmartAttendanceTeacherPageState createState() => _SmartAttendanceTeacherPageState();
}

class _SmartAttendanceTeacherPageState extends State<SmartAttendanceTeacherPage> {
  static const platform = MethodChannel('com.example.present_me/wifi');

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  TextEditingController ssidController = TextEditingController();
  bool attendanceEnabled = false;
  bool isLoading = false;
  List<StudentAttendance> studentList = [];
  bool hotspotEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchHotspotSSID();
    checkHotspotStatus();
    listenAttendanceUpdates();
  }

  Future<void> checkHotspotStatus() async {
    try {
      final bool result = await platform.invokeMethod('isHotspotEnabled');
      setState(() {
        hotspotEnabled = result;
      });
    } on PlatformException catch (e) {
      print('Failed to get hotspot status: ${e.message}');
      setState(() {
        hotspotEnabled = false;
      });
    }
  }

  Future<void> openHotspotSettings() async {
    try {
      await platform.invokeMethod('openHotspotSettings');
      // After user returns, re-check hotspot status
      await Future.delayed(Duration(seconds: 1));
      await checkHotspotStatus();
    } on PlatformException catch (e) {
      print('Failed to open hotspot settings: ${e.message}');
    }
  }

  void fetchHotspotSSID() async {
    final user = auth.currentUser;
    if (user == null) return;
    final doc = await firestore.collection('teachers').doc(user.uid).get();
    if (doc.exists) {
      final ssid = doc.data()?['hotspot'] ?? '';
      ssidController.text = ssid;
    }
  }

  void enableAttendance() async {
    if (!hotspotEnabled) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Hotspot Not Enabled'),
          content: Text('To enable attendance, please turn on your device\'s hotspot.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await openHotspotSettings();
        await checkHotspotStatus();
      }

      return;
    }

    if (ssidController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enter Hotspot SSID')));
      return;
    }

    setState(() => isLoading = true);
    final user = auth.currentUser;
    if (user == null) return;

    final sessionData = {
      "enabled": true,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "wifiSSID": ssidController.text.trim(),
      "className": widget.className,
      "classCode": widget.classCode,
      "teacherId": user.uid,
    };

    try {
      await firestore.doc('attendanceSessions/${user.uid}_${widget.classCode}').set(sessionData);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance Enabled')));
      setState(() => attendanceEnabled = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to enable attendance')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void disableAttendance() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await firestore.doc('attendanceSessions/${user.uid}_${widget.classCode}').update({'enabled': false});
      await markAbsentStudents();
      setState(() => attendanceEnabled = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to disable attendance')));
    }
  }

  Future<void> markAbsentStudents() async {
    final attendanceRef = firestore.collection('Attendance').doc(widget.classCode);
    final classRef = firestore.collection('classes').doc(widget.classCode);
    final todayDate = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');

    final dateListRef = attendanceRef.collection('DateList').doc('AllDates');
    await dateListRef.set({
      'dates': FieldValue.arrayUnion([todayDate])
    }, SetOptions(merge: true));

    final classDoc = await classRef.get();
    final students = List<String>.from(classDoc.data()?['students'] ?? []);

    final attendanceTodayRef = attendanceRef.collection(todayDate);
    final presentSnapshot = await attendanceTodayRef.get();
    final presentIds = presentSnapshot.docs.map((d) => d.id).toList();

    final batch = firestore.batch();
    for (var id in students) {
      if (!presentIds.contains(id)) {
        batch.set(attendanceTodayRef.doc(id), {'status': 'Absent'});
      }
    }
    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(presentIds.length == students.length
          ? 'All students are present today.'
          : 'Marked ${students.length - presentIds.length} student(s) as absent.'),
    ));
  }

  void listenAttendanceUpdates() {
    final todayDate = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
    final attendanceRef = firestore.collection('Attendance').doc(widget.classCode).collection(todayDate);

    attendanceRef.where('status', isEqualTo: 'Present').snapshots().listen((snapshot) async {
      final studentIds = snapshot.docs.map((doc) => doc.id).toList();

      if (studentIds.isEmpty) {
        setState(() {
          studentList.clear();
        });
        return;
      }

      final usersSnapshot = await firestore.collection('students')
          .where(FieldPath.documentId, whereIn: studentIds).get();

      final List<StudentAttendance> students = [];
      for (var doc in usersSnapshot.docs) {
        students.add(StudentAttendance(
          name: doc['name'] ?? 'Unknown',
          rollNo: doc['roll'] ?? 'N/A',
          photoUrl: doc['photoUrl'] ?? '',
          status: 'Present',
        ));
      }
      students.sort((a, b) => a.rollNo.compareTo(b.rollNo));

      setState(() {
        studentList = students;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Attendance', style: TextStyle(fontSize: 24, color: Colors.white)),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Class Name: ${widget.className}', style: TextStyle(fontSize: 14)),
                        Text('Class Code: ${widget.classCode}', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 8),
                        TextField(
                          controller: ssidController,
                          decoration: InputDecoration(
                            hintText: 'Hotspot Name',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: Button(
                            text: hotspotEnabled ? 'Hotspot Enabled' : 'Enable Hotspot',
                            onPressed: hotspotEnabled
                                ? null
                                : () async {
                              await openHotspotSettings();
                              await checkHotspotStatus();
                            },
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Present Students: ${studentList.length}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: studentList.isEmpty
                    ? Center(child: Text('No Present Students'))
                    : GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: studentList.length,
                  itemBuilder: (context, index) {
                    final student = studentList[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: student.photoUrl.isNotEmpty
                                ? NetworkImage(student.photoUrl)
                                : AssetImage('assets/placeholder_profile.png') as ImageProvider,
                          ),
                          SizedBox(height: 8),
                          Text(
                            student.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            student.rollNo,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: attendanceEnabled ? disableAttendance : enableAttendance,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith((states) => null),
                    elevation: MaterialStateProperty.all(0),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        attendanceEnabled ? 'Disable Attendance' : 'Enable Attendance',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentAttendance {
  final String name;
  final String rollNo;
  final String photoUrl;
  final String status;

  StudentAttendance({
    required this.name,
    required this.rollNo,
    required this.photoUrl,
    required this.status,
  });
}
