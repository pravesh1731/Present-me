import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:present_me_flutter/core/widgets/header.dart';

List<Map<String, dynamic>> forClass(String classCode) {
  return [
    {'name': 'John Smith', 'roll': '1', 'uid': 'st_1', 'photoUrl': ''},
    {'name': 'Emma Johnson', 'roll': '2', 'uid': 'st_2', 'photoUrl': ''},
    {'name': 'Michael Brown', 'roll': '3', 'uid': 'st_3', 'photoUrl': ''},
    {'name': 'Sophia Davis', 'roll': '4', 'uid': 'st_4', 'photoUrl': ''},
  ];
}

class ManualAttendanceMain extends StatefulWidget {
  final String className;
  final String classCode;

  ManualAttendanceMain({required this.className, required this.classCode});

  @override
  _ManualAttendanceMainState createState() => _ManualAttendanceMainState();
}

class _ManualAttendanceMainState extends State<ManualAttendanceMain> {
  bool isAttendanceFinalized = false;
  Map<String, String> savedStatuses = {};

  // Local refresh trigger so StreamBuilders can rebuild when in-memory data changes.
  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  String dateKey() {
    final dateFormat = DateFormat('yyyyMMdd');
    return dateFormat.format(DateTime.now());
  }

  String _prettyDate() {
    // Example: Saturday, March 14, 2026
    return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  Color get _accentStart => const Color(0xFF4F46E5);
  Color get _accentEnd => const Color(0xFF2563EB);
  Color get _pageBgTop => const Color(0xFFF3F7FF);
  Color get _pageBgBottom => const Color(0xFFF7FAFF);

  Future<void> finalizeAttendance(List<Map<String, dynamic>> students) async {
    final allMarked = students.every(
      (student) =>
          student['status'] == 'Present' || student['status'] == 'Absent',
    );

    if (!allMarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mark attendance for all students.')),
      );
      return;
    }

    setState(() {
      isAttendanceFinalized = true;
    });
  }

  void showConfirmationDialog(List<Map<String, dynamic>> students) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Submit Attendance'),
          content: const Text(
            'Are you sure you want to submit today\'s attendance?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                finalizeAttendance(students);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentEnd,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Trigger initial load for StreamBuilders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshController.add(null);
    });
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBgBottom,
      body: Column(
        children: [
          Stack(
            children: [
              Header(
                heading: "Manual Attendance",
                subheading: widget.classCode,
              ),
              Positioned(
                right: 16,
                bottom: 26,
                child: SafeArea(
                  top: false,
                  child: Text(
                    _prettyDate(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: forClass(widget.classCode).length,
              itemBuilder: (context, index) {
                final student = forClass(widget.classCode)[index];

                final name = student['name'] ?? 'Unknown';
                final roll = student['roll'] ?? '';
                final email = student['email'] ?? '';

                return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                        children: [

                          /// AVATAR
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          /// STUDENT INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  roll.isEmpty ? '—' : 'ST${roll.padLeft(3, '0')}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),

                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B7280),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// PRESENT BUTTON
                          IconAction(
                            enabled: !isAttendanceFinalized,
                            bg: const Color(0xFFDDFBE7),
                            fg: const Color(0xFF16A34A),
                            icon: Icons.check,
                            onTap: (){},
                          ),

                          const SizedBox(width: 10),

                          /// ABSENT BUTTON
                          IconAction(
                            enabled: !isAttendanceFinalized,
                            bg: const Color(0xFFFCE1E1),
                            fg: const Color(0xFFDC2626),
                            icon: Icons.close,
                            onTap: (){},
                          ),
                        ]
                    )
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



class IconAction extends StatelessWidget {
  final bool enabled;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback onTap;

  const IconAction({
    required this.enabled,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: fg, size: 28),
        ),
      ),
    );
  }
}
