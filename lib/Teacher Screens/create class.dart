import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'classDetailsStudentList.dart';


class CreateClass extends StatefulWidget {
  @override
  State<CreateClass> createState() => _CreateClassState();
}

class _CreateClassState extends State<CreateClass> {
  int _selectedTab = 0; // 0: Active, 1: Inactive

  // Filter using Firestore field `isActive`
  List<Map<String, dynamic>> _filterActiveClasses(List<Map<String, dynamic>> classes) {
    return classes.where((c) => (c['isActive'] as bool?) ?? true).toList();
  }

  List<Map<String, dynamic>> _filterInactiveClasses(List<Map<String, dynamic>> classes) {
    return classes.where((c) => !((c['isActive'] as bool?) ?? true)).toList();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Palette: [primary, secondary] per class theme
  static const List<List<Color>> _classThemes = [
    [Color(0xFF10B981), Color(0xFF059669)], // emerald
    [Color(0xFF6366F1), Color(0xFF4F46E5)], // indigo
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // violet
    [Color(0xFFF59E0B), Color(0xFFD97706)], // amber
    [Color(0xFFEF4444), Color(0xFFDC2626)], // red
    [Color(0xFF14B8A6), Color(0xFF0D9488)], // teal
    [Color(0xFF06B6D4), Color(0xFF0891B2)], // cyan
    [Color(0xFFA855F7), Color(0xFF9333EA)], // purple
    [Color(0xFF3B82F6), Color(0xFF2563EB)], // blue
    [Color(0xFFF97316), Color(0xFFEA580C)], // orange
  ];

  void _showCreateClassDialog() {
    final classNameController = TextEditingController();
    final roomController = TextEditingController();
    final maxStudentsController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    Set<String> selectedDays = {};

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
          elevation: 24,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient Header
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF2563EB)], // cyan-500 to blue-600
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New Class',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Set up your class details',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Flexible(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)], // cyan-50 to blue-50
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class Name
                          Row(
                            children: [
                              Icon(Icons.menu_book, color: Colors.teal.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Class Name',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: classNameController,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'e.g., Grade 10 - Mathematics',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                                borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Room Number
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.teal.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text('Room Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: roomController,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'e.g., 301',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                                borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Start and End Time Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, color: Colors.teal.shade600, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Start Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) {
                                          setState(() => startTime = picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              startTime?.format(context) ?? '--:-- --',
                                              style: TextStyle(
                                                color: startTime == null ? Colors.grey.shade400 : Colors.black87,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(Icons.schedule, color: Colors.grey.shade400, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, color: Colors.teal.shade600, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('End Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (picked != null) {
                                          setState(() => endTime = picked);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              endTime?.format(context) ?? '--:-- --',
                                              style: TextStyle(
                                                color: endTime == null ? Colors.grey.shade400 : Colors.black87,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(Icons.schedule, color: Colors.grey.shade400, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Class Days
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.teal.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text('Class Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                              final isSelected = selectedDays.contains(day);
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedDays.remove(day);
                                      } else {
                                        selectedDays.add(day);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                        colors: [
                                          Color(0xFF06B6D4), // cyan-500
                                          Color(0xFF2563EB),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                          : null,
                                      color: isSelected ? null : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          // Create Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF06B6D4), // cyan-500
                                  Color(0xFF2563EB),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  if (classNameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.warning_rounded, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Please enter class name'),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    return;
                                  }

                                  final code = (Random().nextInt(900000) + 100000).toString();
                                  final uid = _auth.currentUser?.uid;

                                  if (uid != null) {
                                    final classData = {
                                      'name': classNameController.text.trim(),
                                      'code': code,
                                      'room': roomController.text.trim(),
                                      'maxStudents': maxStudentsController.text.trim(),
                                      'startTime': startTime?.format(context) ?? '',
                                      'endTime': endTime?.format(context) ?? '',
                                      'days': selectedDays.toList(),
                                      'createdBy': uid,
                                      'students': [],
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'isActive': true, // default active
                                    };

                                    await _firestore.collection('classes').doc(code).set(classData);
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle_rounded, color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text('Class "${classNameController.text.trim()}" created!'),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
                                      SizedBox(width: 10),
                                      Text(
                                        'Create Class',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditClassDialog(String code) async {
    // Fetch the class data first
    final classDoc = await _firestore.collection('classes').doc(code).get();
    if (!classDoc.exists) return;

    final classData = classDoc.data()!;
    final classNameController = TextEditingController(text: classData['name'] ?? '');
    final roomController = TextEditingController(text: classData['room'] ?? '');

    TimeOfDay? startTime;
    TimeOfDay? endTime;

    // Parse existing times
    if (classData['startTime'] != null && (classData['startTime'] as String).isNotEmpty) {
      final parts = (classData['startTime'] as String).split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0].trim());
        final minute = int.tryParse(parts[1].split(' ')[0].trim());
        final period = (classData['startTime'] as String).toLowerCase().contains('pm') ? 'PM' : 'AM';
        if (hour != null && minute != null) {
          startTime = TimeOfDay(
            hour: period == 'PM' && hour != 12 ? hour + 12 : (period == 'AM' && hour == 12 ? 0 : hour),
            minute: minute,
          );
        }
      }
    }

    if (classData['endTime'] != null && (classData['endTime'] as String).isNotEmpty) {
      final parts = (classData['endTime'] as String).split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0].trim());
        final minute = int.tryParse(parts[1].split(' ')[0].trim());
        final period = (classData['endTime'] as String).toLowerCase().contains('pm') ? 'PM' : 'AM';
        if (hour != null && minute != null) {
          endTime = TimeOfDay(
            hour: period == 'PM' && hour != 12 ? hour + 12 : (period == 'AM' && hour == 12 ? 0 : hour),
            minute: minute,
          );
        }
      }
    }

    Set<String> selectedDays = Set<String>.from(classData['days'] ?? []);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
          elevation: 24,
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gradient Header
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF2563EB)], // cyan-500 to blue-600
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 18),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Class',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Update your class details',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Flexible(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)], // cyan-50 to blue-50
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class Name
                          Row(
                            children: [
                              Icon(Icons.menu_book, color: Colors.teal.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Class Name',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: classNameController,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'e.g., Grade 10 - Mathematics',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                                borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Room Number
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Colors.teal.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text('Room Number', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: roomController,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'e.g., 301',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(14)),
                                borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Start and End Time Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, color: Colors.teal.shade600, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Start Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: startTime ?? TimeOfDay.now(),
                                            builder: (context, child) {
                                              return Theme(
                                                data: ThemeData.light().copyWith(
                                                  colorScheme: const ColorScheme.light(
                                                    primary: Color(0xFF2563EB),
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setState(() => startTime = picked);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                startTime?.format(context) ?? 'Select time',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: startTime != null ? Colors.black87 : Colors.grey.shade400,
                                                ),
                                              ),
                                              Icon(Icons.schedule, color: Colors.grey.shade400, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time_filled, color: Colors.teal.shade600, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('End Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: endTime ?? TimeOfDay.now(),
                                            builder: (context, child) {
                                              return Theme(
                                                data: ThemeData.light().copyWith(
                                                  colorScheme: const ColorScheme.light(
                                                    primary: Color(0xFF2563EB),
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setState(() => endTime = picked);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade200, width: 1.5),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                endTime?.format(context) ?? 'Select time',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: endTime != null ? Colors.black87 : Colors.grey.shade400,
                                                ),
                                              ),
                                              Icon(Icons.schedule, color: Colors.grey.shade400, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Days of the Week
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.teal.shade600, size: 20),
                              const SizedBox(width: 8),
                              const Text('Select Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                              final isSelected = selectedDays.contains(day);
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedDays.remove(day);
                                      } else {
                                        selectedDays.add(day);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                        colors: [
                                          Color(0xFF06B6D4), // cyan-500
                                          Color(0xFF2563EB),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                          : null,
                                      color: isSelected ? null : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                          : null,
                                    ),
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          // Update Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF06B6D4), // cyan-500
                                  Color(0xFF2563EB),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  if (classNameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.warning_rounded, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Please enter class name'),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFFEF4444),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    return;
                                  }

                                  final updatedData = {
                                    'name': classNameController.text.trim(),
                                    'room': roomController.text.trim(),
                                    'startTime': startTime?.format(context) ?? '',
                                    'endTime': endTime?.format(context) ?? '',
                                    'days': selectedDays.toList(),
                                  };

                                  await _firestore.collection('classes').doc(code).update(updatedData);

                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text('Class updated successfully!'),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Update Class',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getClassesStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.empty();

    return _firestore
        .collection('classes')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'],
          'code': data['code'],
          'createdAt': data['createdAt'],
          'isActive': data['isActive'] ?? true,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateClassDialog,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Create Class',
      ),
      body: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFECFEFF), // cyan-50
                Color(0xFFEFF6FF), // blue-50
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getClassesStream(),
            builder: (context, snapshot) {
              final classes = snapshot.data ?? [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading classes'));
              }

              // compute once
              final activeClasses = _filterActiveClasses(classes);
              final inactiveClasses = _filterInactiveClasses(classes);
              final showClasses = _selectedTab == 0 ? activeClasses : inactiveClasses;

              return Column(
                children: [
                  _buildHeader(activeClasses.length), // header always uses active count
                  const SizedBox(height: 12),
                  // Active/Inactive Tabs (interactive)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _selectedTab == 0
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Active',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${activeClasses.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _selectedTab == 1
                                  ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Inactive',
                                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${inactiveClasses.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (showClasses.isEmpty) {
                          return Center(
                            child: Text(
                              _selectedTab == 0 ? 'No Active Classes' : 'No Inactive Classes',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: showClasses.length,
                          itemBuilder: (context, index) {
                            final c = showClasses[index];
                            final theme = _classThemes[index % _classThemes.length];
                            return _buildClassCard(
                              context,
                              name: c['name'] ?? 'Class',
                              code: c['code'] ?? '--',
                              dayBadges: _demoDayBadges(index),
                              timeLabel: _demoTimeLabel(index),
                              roomLabel: 'Room ${301 + index % 5}',
                              studentsCount: 20 + (index * 3) % 15,
                              attendance: index.isEven ? 94 : 89,
                              primary: theme[0],
                              secondary: theme[1],
                              isActive: c['isActive'] ?? true,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Header similar to screenshot: rounded gradient with title and add button
  Widget _buildHeader(int activeCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.fromLTRB(20, 44, 16, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF06B6D4), // cyan-500
            Color(0xFF2563EB), // blue-600
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Classes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$activeCount active classes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
      BuildContext context, {
        required String name,
        required String code,
        required List<String> dayBadges,
        required String timeLabel,
        required String roomLabel,
        required int studentsCount,
        required int attendance,
        required Color primary,
        required Color secondary,
        required bool isActive,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => classDetailsStudentList(classCode: code), // Pass class code
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top accent bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [_soften(primary, 0.30), _soften(secondary, 0.30)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_tint(primary, 0.95), _tint(primary, 0.90)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primary.withOpacity(0.18)),
                        ),
                        child: Icon(Icons.menu_book_outlined, color: secondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: -6,
                              children: dayBadges.map((d) => _buildBadge(d)).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        color: Colors.white,
                        elevation: 8,
                        offset: const Offset(0, 8),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showEditClassDialog(code);
                          } else if (value == 'toggle_active') {
                            await _firestore.collection('classes').doc(code).update({
                              'isActive': !isActive,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      !isActive ? Icons.check_circle_rounded : Icons.archive_outlined,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        !isActive
                                            ? 'Moved to Active classes'
                                            : 'Moved to Inactive classes',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                !isActive ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.6),
                              builder: (_) => Dialog(
                                insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 440),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Red & Pink gradient header
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(28),
                                            topRight: Radius.circular(28),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.topRight,
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(20),
                                                  onTap: () => Navigator.pop(context, false),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    child: const Icon(Icons.close,
                                                        color: Colors.white, size: 24),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.warning_rounded,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Text(
                                              'Delete Class?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'This action cannot be undone',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // White content section
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(28),
                                            bottomRight: Radius.circular(28),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEE2E2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: const [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Color(0xFFEF4444),
                                                        size: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Warning',
                                                        style: TextStyle(
                                                          color: Color(0xFFEF4444),
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Deleting "$name" will permanently remove:',
                                                    style: const TextStyle(
                                                      color: Color(0xFF991B1B),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _buildWarningItem('All class attendance records'),
                                                  const SizedBox(height: 6),
                                                  _buildWarningItem('Student enrollment data'),
                                                  const SizedBox(height: 6),
                                                  _buildWarningItem('Class notes and materials'),
                                                  const SizedBox(height: 6),
                                                  _buildWarningItem('Grade and score history'),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    style: OutlinedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                                      side: const BorderSide(
                                                          color: Color(0xFFD1D5DB), width: 1.5),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Color(0xFF6B7280),
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFFEF4444), Color(0xFFEC4899)],
                                                        begin: Alignment.centerLeft,
                                                        end: Alignment.centerRight,
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFFEF4444)
                                                              .withOpacity(0.35),
                                                          blurRadius: 12,
                                                          offset: const Offset(0, 5),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(12),
                                                        onTap: () => Navigator.pop(context, true),
                                                        child: const Padding(
                                                          padding: EdgeInsets.symmetric(vertical: 12),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.delete_outline,
                                                                  size: 20, color: Colors.white),
                                                              SizedBox(width: 8),
                                                              Text(
                                                                'Delete Class',
                                                                style: TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            const Center(
                                              child: Text(
                                                'Consider archiving instead of deleting to preserve records',
                                                style: TextStyle(
                                                  color: Color(0xFF9CA3AF),
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              );

                          if (confirm == true) {
                            await _firestore.collection('classes').doc(code).delete();
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20, color: primary),
                              const SizedBox(width: 12),
                              const Text('Edit Class', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_active',
                          child: Row(
                            children: [
                              Icon(
                                isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                                size: 20,
                                color: isActive
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isActive ? 'Move to Inactive' : 'Move to Active',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 20, color: Color(0xFFEF4444)),
                              SizedBox(width: 12),
                              Text('Delete Class', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(timeLabel, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(width: 16),
                    const Icon(Icons.room_outlined, size: 16, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(roomLabel, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_outlined,
                                  size: 16, color: Colors.black45),
                              const SizedBox(width: 6),
                              Text(
                                '$studentsCount students',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          _buildCodeBadge(code, primary),
                        ],
                      ),
                    ),
                    _buildAttendancePill(attendance),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          )
        ],
      ),
      )
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendancePill(int percent) {
    final color = percent >= 90 ? const Color(0xFF10B981) : const Color(0xFFF97316);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$percent% attendance',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  List<String> _demoDayBadges(int index) {
    const sets = [
      ['Mon', 'Wed', 'Fri'],
      ['Tue', 'Thu'],
      ['Mon', 'Thu'],
    ];
    return sets[index % sets.length];
  }

  String _demoTimeLabel(int index) {
    const times = [
      '9:00 - 10:00 AM',
      '10:30 - 11:30 AM',
      '12:00 - 1:00 PM',
    ];
    return times[index % times.length];
  }

  Widget _buildDayRangeBadge(List<String> days) {
    final label = days.join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Color _tint(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  Widget _buildCodeBadge(String code, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tint(primary, 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key_rounded, size: 14, color: primary),
          const SizedBox(width: 4),
          Text(
            code,
            style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _soften(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }
}
