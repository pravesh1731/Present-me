import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import '../../core/constants/constants.dart';

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

class _SmartAttendanceStudentPageState
    extends State<SmartAttendanceStudentPage> {
  static const platform = MethodChannel('com.example.present_me/wifi');
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? teacherSSID;
  bool attendanceEnabled = false;
  bool attendanceMarked = false;
  bool isLoading = false;
  bool isSessionLoading = true;
  String statusMessage = "Loading session...";
  String authButtonText = "Mark Attendance";
  String? sessionError;

  Timer? _wifiCheckTimer;

  @override
  void initState() {
    super.initState();
    _initFlow();
    _wifiCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _checkCurrentSSID();
    });
  }

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initFlow() async {
    await _requestPermissions();
    await _getSessionAndSSID();
    await _checkCurrentSSID();
    await _updateAuthButtonText();
  }

  Future<void> _requestPermissions() async {
    if (!await Permission.location.isGranted) {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            statusMessage = "Location permission required.";
            isSessionLoading = false;
          });
        }
        return;
      }
    }

    try {
      final enabled =
      await platform.invokeMethod<bool>('isLocationEnabled');
      if (enabled != true) {
        if (mounted) {
          setState(() {
            statusMessage = "Please enable location services.";
            isSessionLoading = false;
          });
        }
        return;
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          statusMessage = "Please enable location services.";
          isSessionLoading = false;
        });
      }
    }
  }

  Future<void> _getSessionAndSSID() async {
    if (mounted) {
      setState(() {
        isSessionLoading = true;
        sessionError = null;
      });
    }

    try {
      final token = getToken();
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final res = await http.get(
        Uri.parse(
            '$baseUrl/students/attendance-session/${widget.classCode}?date=$dateKey'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('Session response: ${res.statusCode} ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Condition 1: SSID must exist
        final ssid = (data['wifiSSID'] as String?)?.trim();
        if (ssid == null || ssid.isEmpty) {
          if (mounted) {
            setState(() {
              sessionError = "No hotspot session configured.";
              statusMessage = "No active session.";
              attendanceEnabled = false;
              isSessionLoading = false;
            });
          }
          return;
        }

        // Condition 2: enabled must be true
        final enabled = data['enabled'] as bool? ?? false;
        final alreadyMarked = data['alreadyMarked'] as bool? ?? false;

        if (mounted) {
          setState(() {
            teacherSSID = ssid;
            attendanceEnabled = enabled;
            attendanceMarked = alreadyMarked;
            isSessionLoading = false;

            if (alreadyMarked) {
              statusMessage = "Attendance already marked today.";
            } else if (!enabled) {
              statusMessage = "Attendance is disabled by the teacher.";
            }
          });
        }
      } else if (res.statusCode == 404) {
        if (mounted) {
          setState(() {
            sessionError = "No attendance session started by teacher.";
            statusMessage = "Session not found.";
            attendanceEnabled = false;
            isSessionLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            sessionError = "Failed to load session.";
            statusMessage = "Error loading session.";
            attendanceEnabled = false;
            isSessionLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Session error: $e');
      if (mounted) {
        setState(() {
          sessionError = "Network error. Check your connection.";
          statusMessage = "Network error.";
          attendanceEnabled = false;
          isSessionLoading = false;
        });
      }
    }
  }

  Future<void> _checkCurrentSSID() async {
    if (teacherSSID == null || !attendanceEnabled || attendanceMarked) {
      return;
    }

    final currentSSID = await _getCurrentSSID();
    debugPrint('Current SSID: $currentSSID | Teacher SSID: $teacherSSID');

    if (mounted) {
      setState(() {
        if (currentSSID == null) {
          statusMessage = "Unable to detect Wi-Fi.";
        } else if (currentSSID.toLowerCase() ==
            teacherSSID!.toLowerCase()) {
          statusMessage = "Connected to correct Wi-Fi.";
        } else {
          statusMessage =
          'Connect to Teacher Hotspot only to mark attendance.';
        }
      });
    }
  }

  Future<String?> _getCurrentSSID() async {
    try {
      final ssid = await platform.invokeMethod<String>('getSSID');
      return ssid?.replaceAll('"', '').trim();
    } on PlatformException catch (e) {
      debugPrint("Failed to get SSID: '${e.message}'.");
      return null;
    }
  }

  Future<void> _updateAuthButtonText() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() {
          authButtonText =
          (canCheckBiometrics || isDeviceSupported)
              ? "Authenticate & Mark Attendance"
              : "Mark Attendance";
        });
      }
    } catch (_) {
      if (mounted) setState(() => authButtonText = "Mark Attendance");
    }
  }

  Future<void> _authenticateAndMarkAttendance() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      bool isAuthenticated = false;

      if (canCheckBiometrics) {
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to mark attendance',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
      } else if (isDeviceSupported) {
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to mark attendance',
          options: const AuthenticationOptions(
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
      } else {
        await _markAttendance();
        return;
      }

      if (isAuthenticated) {
        await _markAttendance();
      } else {
        _showSnackBar("Authentication failed. Try again.");
      }
    } catch (e) {
      _showSnackBar("Authentication error: ${e.toString()}");
    }
  }

  Future<void> _markAttendance() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final token = getToken();
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final res = await http.post(
        Uri.parse('$baseUrl/students/mark-smart-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'classCode': widget.classCode,
          'date': dateKey,
          'status': 1,
        }),
      );

      debugPrint('Mark attendance response: ${res.statusCode} ${res.body}');
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            attendanceMarked = true;
            statusMessage = "Attendance marked successfully!";
          });
        }
        _showSnackBar("Attendance marked successfully!");
      } else if (res.statusCode == 409) {
        // Already marked — update UI
        if (mounted) {
          setState(() {
            attendanceMarked = true;
            statusMessage = "Attendance already marked today.";
          });
        }
        _showSnackBar("Attendance already marked.");
      } else {
        _showSnackBar(data['message'] ?? "Failed to mark attendance.");
      }
    } catch (e) {
      debugPrint('Mark attendance error: $e');
      _showSnackBar("Network error. Try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getStatusColor() {
    switch (statusMessage) {
      case "Connected to correct Wi-Fi.":
        return const Color(0xFF00A76F);
      case "Attendance already marked today.":
      case "Attendance marked successfully!":
        return Colors.blue;
      case "Attendance is disabled by the teacher.":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (statusMessage) {
      case "Connected to correct Wi-Fi.":
        return Icons.wifi;
      case "Attendance already marked today.":
      case "Attendance marked successfully!":
        return Icons.check_circle_outline;
      case "Attendance is disabled by the teacher.":
        return Icons.lock_outline;
      default:
        return Icons.wifi_off_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = attendanceEnabled &&
        !attendanceMarked &&
        !isSessionLoading &&
        sessionError == null &&
        statusMessage == "Connected to correct Wi-Fi.";

    final statusColor = _getStatusColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF7),
      body: Column(
        children: [
          Header(
            heading: 'Smart Attendance',
            subheading: 'WiFi/Hotspot based attendance',
          ),
          Expanded(
            child: isSessionLoading
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: Color(0xFF00A76F)),
                  SizedBox(height: 16),
                  Text("Loading attendance session..."),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // Class + Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A76F)
                                    .withOpacity(0.12),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.menu_book_outlined,
                                color: Color(0xFF00A76F),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.className,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.classCode,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Status pill
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: statusColor.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getStatusIcon(),
                                color: statusColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  statusMessage,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Retry on error
                        if (sessionError != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _getSessionAndSSID();
                                await _checkCurrentSSID();
                              },
                              icon: const Icon(Icons.refresh,
                                  size: 16),
                              label: const Text("Retry"),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],

                      ],
                    ),
                  ),

                  const Spacer(),

                  // Mark Attendance Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: attendanceMarked
                              ? [Colors.grey, Colors.grey]
                              : isButtonEnabled
                              ? [
                            const Color(0xFF00C6FF),
                            const Color(0xFF0072FF),
                          ]
                              : [
                            Colors.grey.shade400,
                            Colors.grey.shade500,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: isButtonEnabled && !isLoading
                            ? _authenticateAndMarkAttendance
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14),
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
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              attendanceMarked
                                  ? Icons.check_circle
                                  : Icons.fingerprint,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              attendanceMarked
                                  ? "Attendance Marked"
                                  : authButtonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}