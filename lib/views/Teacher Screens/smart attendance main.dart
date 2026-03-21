import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:present_me_flutter/core/widgets/header.dart';

class SmartAttendanceTeacherPage extends StatefulWidget {
  final String className;
  final String classCode;
  final int totalStudents;

  const SmartAttendanceTeacherPage({
    Key? key,
    required this.className,
    required this.classCode,
    required this.totalStudents,
  }) : super(key: key);

  @override
  _SmartAttendanceTeacherPageState createState() =>
      _SmartAttendanceTeacherPageState();
}

class _SmartAttendanceTeacherPageState
    extends State<SmartAttendanceTeacherPage> {
  static const platform = MethodChannel('com.example.present_me/wifi');

  static const Color _connectedGreen = Color(0xFF00A76F);
  static const Color _disconnectedOrange = Color(0xFFFF6A00);
  static const Color _disconnectedRed = Color(0xFFFF2D55);

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
      debugPrint('Failed to get hotspot status: ${e.message}');
      setState(() => hotspotEnabled = false);
    }
  }

  Future<void> openHotspotSettings() async {
    try {
      await platform.invokeMethod('openHotspotSettings');
      await Future.delayed(const Duration(seconds: 1));
      await checkHotspotStatus();
    } on PlatformException catch (e) {
      debugPrint('Failed to open hotspot settings: ${e.message}');
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
    final attendanceRef =
    firestore.collection('Attendance').doc(widget.classCode);
    final classRef = firestore.collection('classes').doc(widget.classCode);
    final todayDate = DateTime.now()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');

    await attendanceRef.collection('DateList').doc('AllDates').set(
      {'dates': FieldValue.arrayUnion([todayDate])},
      SetOptions(merge: true),
    );

    final classDoc = await classRef.get();
    final students =
    List<String>.from(classDoc.data()?['students'] ?? []);

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
    final todayDate = DateTime.now()
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    final attendanceRef = firestore
        .collection('Attendance')
        .doc(widget.classCode)
        .collection(todayDate);

    attendanceRef
        .where('status', isEqualTo: 'Present')
        .snapshots()
        .listen((snapshot) async {
      final studentIds = snapshot.docs.map((doc) => doc.id).toList();
      if (studentIds.isEmpty) {
        setState(() => studentList.clear());
        return;
      }

      final usersSnapshot = await firestore
          .collection('students')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      final students = usersSnapshot.docs
          .map((doc) => StudentAttendance(
        name: doc['name'] ?? 'Unknown',
        rollNo: doc['roll'] ?? 'N/A',
        photoUrl: doc['photoUrl'] ?? '',
        status: 'Present',
      ))
          .toList()
        ..sort((a, b) => a.rollNo.compareTo(b.rollNo));

      setState(() => studentList = students);
    });
  }

  Future<bool?> _showHotspotDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hotspot Not Enabled'),
        content: const Text(
            'To enable attendance, please turn on your device\'s hotspot.'),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF7),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _buildAttendanceButton(), // ← no extra padding inside
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            heading: "Smart Attendance",
            subheading: "WiFi/Hotspot Based Attendance",
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHotspotStatusCard(),
                  const Padding(
                    padding: EdgeInsets.only(left: 18.0, top: 4, bottom: 4),
                    child: Text(
                      "Class Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildClassInfoSection(),
                  _buildPresentStudentCount(),
                  const SizedBox(height: 8),
                  _buildStudentGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotStatusCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: hotspotEnabled
              ? const LinearGradient(
            colors: [_connectedGreen, _connectedGreen],
          )
              : const LinearGradient(
            colors: [_disconnectedOrange, _disconnectedRed],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.wifi_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hotspot Status',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hotspotEnabled ? 'Connected & Ready' : 'Not Connected',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!hotspotEnabled)
              SizedBox(
                height: 32,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () async {
                    await openHotspotSettings();
                    await checkHotspotStatus();
                  },
                  child: const Text(
                    'Enable',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Class Name",
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(widget.className,
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Class Code",
                        style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(widget.classCode,
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Students",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text('${widget.totalStudents} enrolled',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: TextField(
                controller: ssidController,
                decoration: InputDecoration(
                  hintText: 'Hotspot Name',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentStudentCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        'Present Students: ${studentList.length}',
        style:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStudentGrid() {
    if (studentList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No Present Students')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
                  backgroundImage: student.photoUrl.isNotEmpty &&
                      (student.photoUrl.startsWith('http://') ||
                          student.photoUrl.startsWith('https://'))
                      ? NetworkImage(student.photoUrl)
                      : const AssetImage(
                      'assets/placeholder_profile.png')
                  as ImageProvider,
                ),
                const SizedBox(height: 8),
                Text(
                  student.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.rollNo,
                  style:
                  TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ← clean button — no extra Padding wrapper inside
  Widget _buildAttendanceButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: attendanceEnabled
                ? [const Color(0xFFFF6A00), const Color(0xFFFF2D55)]
                : [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : attendanceEnabled
              ? disableAttendance
              : enableAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Text(
            attendanceEnabled
                ? 'Disable Attendance'
                : 'Enable Attendance',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
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