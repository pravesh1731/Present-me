import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import '../../core/constants/constants.dart';

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

  final TextEditingController ssidController = TextEditingController();

  bool attendanceEnabled = false;
  bool hotspotEnabled = false;
  bool isLoading = false;
  bool isPageLoading = true;
  List<StudentAttendance> studentList = [];
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    ssidController.dispose();
    super.dispose();
  }

  Future<void> _initPage() async {
    await checkHotspotStatus();
    await _checkExistingSession();
    _startPollingPresentStudents();
    if (mounted) setState(() => isPageLoading = false);
  }

  Future<void> _checkExistingSession() async {
    try {
      final token = getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/teachers/session-status/${widget.classCode}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            attendanceEnabled = data['enabled'] ?? false;
            if (data['wifiSSID'] != null &&
                (data['wifiSSID'] as String).isNotEmpty) {
              ssidController.text = data['wifiSSID'];
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to check session: $e');
    }
  }

  void _startPollingPresentStudents() {
    _fetchPresentStudents();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchPresentStudents();
    });
  }

  Future<void> _fetchPresentStudents() async {
    try {
      final token = getToken();
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final res = await http.get(
        Uri.parse(
            '$baseUrl/teachers/present-students/${widget.classCode}?date=$dateKey'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List students = data['students'] ?? [];
        if (mounted) {
          setState(() {
            studentList = students
                .map((s) => StudentAttendance(
              name: s['name'] ?? s['firstName'] ?? 'Unknown',
              rollNo: s['rollNo'] ?? 'N/A',
              photoUrl: s['profilePicUrl'] ?? '',
              status: 'Present',
            ))
                .toList()
              ..sort((a, b) => a.rollNo.compareTo(b.rollNo));
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch present students: $e');
    }
  }

  Future<void> checkHotspotStatus() async {
    try {
      final bool result = await platform.invokeMethod('isHotspotEnabled');
      if (mounted) setState(() => hotspotEnabled = result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get hotspot status: ${e.message}');
      if (mounted) setState(() => hotspotEnabled = false);
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

    if (mounted) setState(() => isLoading = true);

    try {
      final token = getToken();
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final res = await http.post(
        Uri.parse('$baseUrl/teachers/enable-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'classCode': widget.classCode,
          'className': widget.className,
          'wifiSSID': ssidController.text.trim(),
          'date': dateKey,
        }),
      );

      if (res.statusCode == 200) {
        _showSnackBar('Attendance Enabled ✓');
        if (mounted) setState(() => attendanceEnabled = true);
      } else {
        final data = jsonDecode(res.body);
        _showSnackBar(data['message'] ?? 'Failed to enable attendance');
      }
    } catch (e) {
      _showSnackBar('Network error. Try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> disableAttendance() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final token = getToken();
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final res = await http.post(
        Uri.parse('$baseUrl/teachers/disable-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'classCode': widget.classCode,
          'date': dateKey,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _showSnackBar(
          'Session ended · ${data['presentCount']} present · ${data['absentCount']} absent',
        );
        if (mounted) {
          setState(() {
            attendanceEnabled = false;
            studentList = [];
          });
        }
      } else {
        final data = jsonDecode(res.body);
        _showSnackBar(data['message'] ?? 'Failed to disable attendance');
      }
    } catch (e) {
      _showSnackBar('Network error. Try again.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool?> _showHotspotDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hotspot Not Enabled'),
        content: const Text(
            'To enable attendance, please turn on your device hotspot.'),
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
          child: _buildAttendanceButton(),
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
            child: isPageLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00A76F),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHotspotStatusCard(),
                  const Padding(
                    padding:
                    EdgeInsets.only(left: 18.0, top: 8, bottom: 4),
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
                  const SizedBox(height: 16),
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
              child: const Icon(Icons.wifi_rounded,
                  color: Colors.white, size: 24),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(widget.className,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Class Code",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(widget.classCode,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text("Total Students",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text('${widget.totalStudents} enrolled',
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: TextField(
                controller: ssidController,
                enabled: !attendanceEnabled,
                decoration: InputDecoration(
                  hintText: 'Enter Hotspot Name (SSID)',
                  prefixIcon: const Icon(Icons.wifi,
                      color: Color(0xFF00A76F), size: 20),
                  filled: true,
                  fillColor: attendanceEnabled
                      ? Colors.grey.shade100
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF00A76F), width: 1.5),
                  ),
                ),
              ),
            ),
            if (attendanceEnabled) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Session active · SSID: "${ssidController.text}"',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresentStudentCount() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          const Text(
            'Present Students',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${studentList.length}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const Spacer(),
          if (attendanceEnabled)
            GestureDetector(
              onTap: _fetchPresentStudents,
              child: const Icon(Icons.refresh,
                  color: Color(0xFF00A76F), size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentGrid() {
    if (studentList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                attendanceEnabled
                    ? 'Waiting for students to connect...'
                    : 'Enable attendance to see present students',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
              color: Colors.white,
              border:
              Border.all(color: Colors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
                const SizedBox(height: 6),
                Text(
                  student.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.rollNo,
                  style:
                  TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                attendanceEnabled
                    ? Icons.stop_circle_outlined
                    : Icons.play_circle_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                attendanceEnabled
                    ? 'Disable Attendance'
                    : 'Enable Attendance',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
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