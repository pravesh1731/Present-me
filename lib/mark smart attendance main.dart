import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SmartAttendanceStudentPage extends StatefulWidget {
  final String className;
  final String classCode;

  const SmartAttendanceStudentPage({
    Key? key,
    required this.className,
    required this.classCode,
  }) : super(key: key);

  @override
  _SmartAttendanceStudentPageState createState() =>
      _SmartAttendanceStudentPageState();
}

class _SmartAttendanceStudentPageState extends State<SmartAttendanceStudentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? teacherSSID;
  bool attendanceEnabled = false;
  bool attendanceMarked = false;
  String statusMessage = "Loading...";
  String authButtonText = "Mark Attendance";

  static const platform = MethodChannel('com.example.present_me/wifi');
  final LocalAuthentication _localAuth = LocalAuthentication();

  Timer? _wifiCheckTimer;

  @override
  void initState() {
    super.initState();
    _initPermissionsAndSSID();

    // Auto-refresh Wi-Fi check every 5 seconds
    _wifiCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _checkCurrentSSID();
    });
  }

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPermissionsAndSSID() async {
    if (!await Permission.location.isGranted) {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() => statusMessage = "Location permission not granted.");
        return;
      }
    }

    bool isLocationEnabled = false;
    try {
      final enabled = await platform.invokeMethod<bool>('isLocationEnabled');
      isLocationEnabled = enabled ?? false;
    } on PlatformException {
      isLocationEnabled = false;
    }

    if (!isLocationEnabled) {
      setState(() => statusMessage = "Please enable location services.");
      return;
    }

    try {
      final hotspotEnabled = await platform.invokeMethod<bool>('isHotspotEnabled');
      if (hotspotEnabled == true) {
        _showToast("Hotspot is enabled. Please disable it to mark attendance.");
      }
    } on PlatformException {}

    await _getTeacherSSID();
    await _checkCurrentSSID();
    await _updateAuthButtonText();
  }

  Future<void> _getTeacherSSID() async {
    try {
      DocumentSnapshot classDoc =
      await _firestore.collection("classes").doc(widget.classCode).get();

      if (!classDoc.exists) {
        setState(() {
          statusMessage = "Error: Class not found.";
          attendanceEnabled = false;
        });
        return;
      }

      final teacherId = classDoc.get("createdBy") as String?;

      if (teacherId == null || teacherId.isEmpty) {
        setState(() {
          statusMessage = "Error: Teacher ID not found.";
          attendanceEnabled = false;
        });
        return;
      }

      DocumentSnapshot sessionDoc = await _firestore
          .doc("attendanceSessions/${teacherId}_${widget.classCode}")
          .get();

      if (!sessionDoc.exists) {
        setState(() {
          statusMessage = "Error: Attendance session not found.";
          attendanceEnabled = false;
        });
        return;
      }

      final enabled = sessionDoc.get("enabled") as bool? ?? false;
      final ssid = sessionDoc.get("wifiSSID") as String?;

      setState(() {
        attendanceEnabled = enabled;
        teacherSSID = ssid?.trim();
      });
    } catch (e) {
      setState(() {
        statusMessage = "Failed to retrieve attendance session.";
        attendanceEnabled = false;
      });
    }
  }

  Future<String?> _getCurrentSSID() async {
    try {
      final ssid = await platform.invokeMethod<String>('getSSID');
      return ssid?.replaceAll('"', '').trim();
    } on PlatformException catch (e) {
      print("Failed to get SSID: '${e.message}'.");
      return null;
    }
  }

  Future<void> _checkCurrentSSID() async {
    final currentSSID = await _getCurrentSSID();
    print("Current SSID: $currentSSID");

    setState(() {
      if (currentSSID == null) {
        statusMessage = "Unable to get current Wi-Fi SSID.";
      } else if (teacherSSID != null &&
          currentSSID.toLowerCase() == teacherSSID!.toLowerCase()) {
        if (attendanceEnabled) {
          statusMessage = "Connected to correct Wi-Fi.";
        } else {
          statusMessage = "Attendance is disabled by the teacher.";
        }
      } else {
        statusMessage = "Not connected to the correct Wi-Fi.";
      }
    });
  }

  Future<void> _updateAuthButtonText() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      setState(() {
        if (canCheckBiometrics) {
          authButtonText = "Authenticate with Biometrics";
        } else if (isDeviceSupported) {
          authButtonText = "Authenticate with Passcode";
        } else {
          authButtonText = "Authentication not supported";
        }
      });
    } catch (e) {
      setState(() => authButtonText = "Authentication error");
    }
  }

  Future<void> _authenticateAndMarkAttendance() async {
    try {
      bool isAuthenticated = false;

      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics) {
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to mark attendance',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      } else if (isDeviceSupported) {
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to mark attendance',
          options: const AuthenticationOptions(
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      } else {
        _showToast("Authentication not available on this device.");
        return;
      }

      if (isAuthenticated) {
        await _markAttendance();
      } else {
        _showToast("Authentication failed.");
      }
    } catch (e) {
      _showToast("Authentication error: ${e.toString()}");
    }
  }

  Future<void> _markAttendance() async {
    if (!attendanceEnabled) {
      _showToast("Attendance is not enabled!");
      return;
    }
    if (attendanceMarked) {
      _showToast("Attendance already marked.");
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showToast("User not logged in.");
        return;
      }

      // 👇 format date as yyyyMMdd (like Kotlin)
      final todayDate = DateTime.now();
      final dateKey = "${todayDate.year.toString().padLeft(4, '0')}"
          "${todayDate.month.toString().padLeft(2, '0')}"
          "${todayDate.day.toString().padLeft(2, '0')}";

      // 1️⃣ Save attendance record
      final attendanceRef = _firestore
          .collection("Attendance")
          .doc(widget.classCode)
          .collection(dateKey)
          .doc(user.uid);

      await attendanceRef.set({"status": "Present"});

      // 2️⃣ Update DateList/AllDates/dates array
      final dateListRef = _firestore
          .collection("Attendance")
          .doc(widget.classCode)
          .collection("DateList")
          .doc("AllDates");

      await dateListRef.set({
        "dates": FieldValue.arrayUnion([dateKey])
      }, SetOptions(merge: true));

      setState(() {
        attendanceMarked = true;
        statusMessage = "Attendance marked successfully!";
      });

      _showToast("Attendance marked successfully!");
    } catch (e) {
      _showToast("Failed to mark attendance: ${e.toString()}");
    }
  }


  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = attendanceEnabled &&
        !attendanceMarked &&
        statusMessage == "Connected to correct Wi-Fi." &&
        (authButtonText != "Authentication not supported" &&
            authButtonText != "Authentication error");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Attendance', style: TextStyle(fontSize: 24, color: Colors.white)),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 220,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blueAccent, width: 1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Class Name: ${widget.className}", style: const TextStyle(fontSize: 18)),
                    Text("Class Code: ${widget.classCode}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 20),
                    Text(statusMessage, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: isButtonEnabled ? _authenticateAndMarkAttendance : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonEnabled ? Colors.blue : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: Text(attendanceMarked ? "Attendance Marked" : authButtonText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
