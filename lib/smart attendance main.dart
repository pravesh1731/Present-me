import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:present_me_flutter/components/common/Button/button.dart';

class SmartAttendanceTeacherPage extends StatefulWidget {
  final String className;
  final String classCode;

  const SmartAttendanceTeacherPage({
    Key? key,
    required this.className,
    required this.classCode,
  }) : super(key: key);

  @override
  _SmartAttendanceTeacherPageState createState() =>
      _SmartAttendanceTeacherPageState();
}

class _SmartAttendanceTeacherPageState
    extends State<SmartAttendanceTeacherPage> {
  static const platform = MethodChannel('com.example.present_me/wifi');

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final TextEditingController ssidController = TextEditingController();

  bool attendanceEnabled = false;
  bool hotspotEnabled = false;
  bool isLoading = false;
  List<StudentAttendance> studentList = [];

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await fetchHotspotSSID();
    await checkHotspotStatus();
    listenAttendanceUpdates();
  }

  Future<void> checkHotspotStatus() async {
    try {
      final bool result = await platform.invokeMethod('isHotspotEnabled');
      setState(() => hotspotEnabled = result);
    } on PlatformException catch (e) {
      print('Failed to get hotspot status: ${e.message}');
      setState(() => hotspotEnabled = false);
    }
  }

  Future<void> openHotspotSettings() async {
    try {
      await platform.invokeMethod('openHotspotSettings');
      await Future.delayed(Duration(seconds: 1));
      await checkHotspotStatus();
    } on PlatformException catch (e) {
      print('Failed to open hotspot settings: ${e.message}');
    }
  }

  Future<void> fetchHotspotSSID() async {
    final user = auth.currentUser;
    if (user == null) return;
    final doc = await firestore.collection('teachers').doc(user.uid).get();
    if (doc.exists) {
      ssidController.text = doc.data()?['hotspot'] ?? '';
    }
  }

  Future<void> enableAttendance() async {
    if (!hotspotEnabled) {
      final confirm = await _showHotspotDialog();
      if (confirm != true) return;

      await openHotspotSettings();
      await checkHotspotStatus();
      if (!hotspotEnabled) return;
    }

    if (ssidController.text.trim().isEmpty) {
      _showSnackBar('Enter Hotspot SSID');
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
      await firestore
          .doc('attendanceSessions/${user.uid}_${widget.classCode}')
          .set(sessionData);
      _showSnackBar('Attendance Enabled');
      setState(() => attendanceEnabled = true);
    } catch (_) {
      _showSnackBar('Failed to enable attendance');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> disableAttendance() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await firestore
          .doc('attendanceSessions/${user.uid}_${widget.classCode}')
          .update({'enabled': false});
      await markAbsentStudents();
      setState(() => attendanceEnabled = false);
    } catch (_) {
      _showSnackBar('Failed to disable attendance');
    }
  }

  Future<void> markAbsentStudents() async {
    final attendanceRef = firestore.collection('Attendance').doc(widget.classCode);
    final classRef = firestore.collection('classes').doc(widget.classCode);
    final todayDate = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');

    await attendanceRef.collection('DateList').doc('AllDates').set(
      {'dates': FieldValue.arrayUnion([todayDate])},
      SetOptions(merge: true),
    );

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

    _showSnackBar(
      presentIds.length == students.length
          ? 'All students are present today.'
          : 'Marked ${students.length - presentIds.length} student(s) as absent.',
    );
  }

  void listenAttendanceUpdates() {
    final todayDate = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
    final attendanceRef =
    firestore.collection('Attendance').doc(widget.classCode).collection(todayDate);

    attendanceRef.where('status', isEqualTo: 'Present').snapshots().listen((snapshot) async {
      final studentIds = snapshot.docs.map((doc) => doc.id).toList();
      if (studentIds.isEmpty) {
        setState(() => studentList.clear());
        return;
      }

      final usersSnapshot = await firestore
          .collection('students')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      final students = usersSnapshot.docs.map((doc) => StudentAttendance(
        name: doc['name'] ?? 'Unknown',
        rollNo: doc['roll'] ?? 'N/A',
        photoUrl: doc['photoUrl'] ?? '',
        status: 'Present',
      )).toList()
        ..sort((a, b) => a.rollNo.compareTo(b.rollNo));

      setState(() => studentList = students);
    });
  }

  Future<bool?> _showHotspotDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hotspot Not Enabled'),
        content: const Text('To enable attendance, please turn on your device\'s hotspot.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance', style: TextStyle(fontSize: 24)),
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
      body: SafeArea(
        child: Column(
          children: [
            _buildClassInfoSection(),
            _buildPresentStudentCount(),
            _buildStudentGrid(),
            _buildAttendanceButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class Name: ${widget.className}', style: const TextStyle(fontSize: 14)),
                Text('Class Code: ${widget.classCode}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: ssidController,
                  decoration: InputDecoration(
                    hintText: 'Hotspot Name',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Button(
                    text: hotspotEnabled ? 'Hotspot Enabled' : 'Enable Hotspot',
                    onPressed: hotspotEnabled ? null : () async {
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
    );
  }

  Widget _buildPresentStudentCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Present Students: ${studentList.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStudentGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: studentList.isEmpty
            ? const Center(child: Text('No Present Students'))
            : GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: student.photoUrl.isNotEmpty
                        ? ((student.photoUrl.trim().isNotEmpty && (student.photoUrl.startsWith('http://') || student.photoUrl.startsWith('https://'))) ? NetworkImage(student.photoUrl) : null)
                        : const AssetImage('assets/placeholder_profile.png') as ImageProvider,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    student.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
    );
  }

  Widget _buildAttendanceButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: attendanceEnabled ? disableAttendance : enableAttendance,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) => null),
            elevation: WidgetStateProperty.all(0),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                attendanceEnabled ? 'Disable Attendance' : 'Enable Attendance',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
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
