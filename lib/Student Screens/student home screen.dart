import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:present_me_flutter/Student%20Screens/student%20Sidebar.dart';

import 'student joined class.dart';
import 'student mark attendance.dart';
import 'student profile.dart';
import '../common Page/notifications_page.dart';
import '../src/models/student.dart';
import '../src/bloc/auth/auth_bloc.dart';
import '../src/bloc/auth/auth_state.dart';
import '../Student Authentication/student login screen.dart';

class studentHome extends StatefulWidget {
  @override
  State<studentHome> createState() => _studentHomeState();
}

class _studentHomeState extends State<studentHome> {
  int _selectedIndex = 0;

  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    // No controller initialization needed; AuthBloc is provided at app root
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Try to obtain student from AuthBloc state, fallback to storage
    Student? student;
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final dynamic userMap = authState.user;
      // Ensure we only call Map.from on actual Map objects. Support server oddities
      // where user may be a JSON string or other shape.
      if (userMap is Map) {
        try {
          student = Student.fromJson(Map<String, dynamic>.from(userMap));
        } catch (_) {}
      } else if (userMap is String) {
        try {
          final decoded = jsonDecode(userMap);
          if (decoded is Map) student = Student.fromJson(Map<String, dynamic>.from(decoded));
        } catch (_) {}
      } else if (userMap != null) {
        // If it's some other type (e.g., already a Student-like object), try a best-effort map conversion
        try {
          final maybeMap = Map<String, dynamic>.from(userMap as Map);
          student = Student.fromJson(maybeMap);
        } catch (_) {}
      }
    }
    if (student == null) {
      final storedStudent = box.read('student');
      if (storedStudent != null) {
        try {
          if (storedStudent is Map) {
            student = Student.fromJson(Map<String, dynamic>.from(storedStudent));
          } else if (storedStudent is String) {
            final decoded = jsonDecode(storedStudent);
            if (decoded is Map) student = Student.fromJson(Map<String, dynamic>.from(decoded));
          } else {
            // Attempt best-effort conversion for other map-like types
            final maybeMap = Map<String, dynamic>.from(storedStudent as Map);
            student = Student.fromJson(maybeMap);
          }
        } catch (_) {
          // ignore: if parsing fails, leave student null and show login screen
        }
      }
    }

    // If still null → not logged in (no token)
    final String? token = box.read<String>('token');
    if (token == null || student == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "User not logged in",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Clear storage token and go to login
                  final box = GetStorage();
                  box.remove('token');
                  box.remove('student');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => studentlogin()),
                  );
                },
                child: const Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeScreen(student),
          joined_Class(),
          mark_Attendance_Student(),
          student_Profile(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeScreen(Student student) {
    // Map your Student model fields to UI
    final String fullName = '${student.firstName} ${student.lastName}'.trim();
    final String name = fullName.isEmpty ? 'Student' : fullName;

    final String rollNo = student.rollNo.isEmpty ? '00' : student.rollNo;
    // You don't have grade in DynamoDB yet; using a placeholder
    final String grade = 'Your Class';
    // You also don't have photoUrl yet; can add later

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.only(
                  top: 50, left: 20, right: 20, bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu Icon Column
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          showStudentSidebar(context);
                        },
                      ),
                      // Greeting Column (Center)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wb_sunny_outlined,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Bell Icon Column
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const NotificationsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$grade - Roll No: $rollNo',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.9 * 255).round()),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Attendance',
                          value: '92%',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.class_outlined,
                          label: 'Classes',
                          value: '6',
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.star_outline,
                          label: 'Avg Score',
                          value: '85',
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Icon(Icons.bolt,
                          color: Colors.orange.shade400, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        'Mark\nAttendance',
                        Icons.check_circle_outline,
                        const Color(0xFF10B981),
                            () => _onItemTapped(2),
                      ),
                      _buildQuickAction(
                        'Join\nClass',
                        Icons.video_call_outlined,
                        const Color(0xFF3B82F6),
                            () {},
                      ),
                      _buildQuickAction(
                        'Notes',
                        Icons.note_outlined,
                        const Color(0xFF8B5CF6),
                            () {},
                      ),
                      _buildQuickAction(
                        'Doubts',
                        Icons.quiz_outlined,
                        const Color(0xFFF59E0B),
                            () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Today's Classes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Classes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '4 classes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildClassCard(
                    'Mathematics',
                    '9:00 AM - 10:00 AM',
                    'Mrs. Smith',
                    true,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _buildClassCard(
                    'Physics',
                    '10:30 AM - 11:30 AM',
                    'Mr. Johnson',
                    false,
                    const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityCard(
                    'Test Results Published',
                    'Mathematics Unit Test - Score: 89/100',
                    '2h ago',
                    Icons.trending_up,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    'New Assignment',
                    'Physics Chapter 5 - Due: Oct 20',
                    '5h ago',
                    Icons.assignment_outlined,
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    'Class Rescheduled',
                    'Chemistry Lab moved to 2:00 PM',
                    '1d ago',
                    Icons.calendar_today_outlined,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha((0.3 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
      String title,
      String time,
      String teacher,
      bool isActive,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.book_outlined, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teacher,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.video_call, color: color),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.class_outlined, Icons.class_, 'Classes'),
              _buildNavItem(
                  2, Icons.check_circle_outline, Icons.check_circle, 'Attendance'),
              _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: isSelected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF06B6D4).withAlpha((0.3 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
      String title,
      String description,
      String time,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}
