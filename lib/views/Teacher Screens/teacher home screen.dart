import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/constants/constants.dart';
import '../../models/class.dart';
import '../../viewmodels/teacher_auth/teacher_auth_bloc.dart';
import '../../viewmodels/teacher_class/teacher_class_bloc.dart';
import '../Teacher Authentication/teacher login screen.dart';
import '../common Page/notifications_page.dart';
import 'TeacherAttendance.dart';
import 'create class.dart';
import 'teacher profile.dart';
import 'teacher Sidebar.dart';
import 'package:http/http.dart' as http;

class teacherHome extends StatefulWidget {
  @override
  State<teacherHome> createState() => _teacherHomeState();
}

class _teacherHomeState extends State<teacherHome> {
  int _selectedIndex = 0;
  final box = GetStorage();
  int totalStudents = 0;
  double averageAttendance = 0.0;
  int totalClasses = 0;
  bool isLoadingStudents = false;

  final String formattedDate = DateFormat(
    'EEEE, MMMM d, y',
  ).format(DateTime.now());


  Future getTotalStudentCount() async {
    try{
      setState(() => isLoadingStudents = true);
      final token = getToken();
      final url =
          "$baseUrl/teachers/total-students";

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          totalStudents = data["totalStudents"];
          totalClasses = data["totalClasses"];
          averageAttendance = (data["averageAttendance"] as num?)?.toDouble() ?? 0.0;
        });
      } } catch (e) {
      print("Error fetching students: $e");
    } finally {
      setState(() => isLoadingStudents = false);
    }
  }

  @override
  void initState() {
    getTotalStudentCount();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final token = getToken();
        if (token.isNotEmpty) {
          context.read<TeacherClassBloc>().add(TeacherFetchClasses(token));
        }
      } catch (e) {
      }
    });
  }

  String getTodayName() {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[now.weekday - 1];
  }

  List<ClassModel> filterTodayClasses(List<ClassModel> classes) {
    final today = getTodayName();

    return classes.where((c) {
      return c.classDays.any(
            (day) => day.toLowerCase() == today.toLowerCase(),
      );
    }).toList();
  }

  bool isClassActive(String start, String end) {
    try {
      final now = TimeOfDay.now();

      TimeOfDay parse(String time) {
        final parts = time.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      final startTime = parse(start);
      final endTime = parse(end);

      bool afterStart = now.hour > startTime.hour ||
          (now.hour == startTime.hour && now.minute >= startTime.minute);

      bool beforeEnd = now.hour < endTime.hour ||
          (now.hour == endTime.hour && now.minute <= endTime.minute);

      return afterStart && beforeEnd;
    } catch (_) {
      return false;
    }
  }

  String formatTime(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';

      hour = hour % 12;
      if (hour == 0) hour = 12;

      final minuteStr = minute.toString().padLeft(2, '0');

      return '$hour:$minuteStr $period';
    } catch (e) {
      return time; // fallback if error
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Robust token check: ensure there's a token AND teacher data stored
    final String? token = box.read<String>('token');

    // If we don't have a token or we don't have teacher data stored, force login
    if (token == null || !box.hasData('teacher')) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("User not logged in", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Clear storage token and go to login
                  final box = GetStorage();
                  box.remove('token');
                  box.remove('teacher');
                  box.remove('role');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => teacherLogin()),
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
          _buildHomeScreen(),
          CreateClass(),
          takeAttendnace(),
          teacher_Profile(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                _buildNavItem(1, Icons.book_outlined, Icons.book, 'Classes'),
                _buildNavItem(
                  2,
                  Icons.check_circle_outline,
                  Icons.check_circle,
                  'Attendance',
                ),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    // Use a single variable for teacher display name to avoid shadowing and null issues
    String? teacherName;
    String? department;
    String? profilePicUrl;

    return Container(
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.only(
                top: 40,
                bottom: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF06B6D4), // cyan-500
                    Color(0xFF2563EB), // blue-600
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: BlocBuilder<TeacherAuthBloc, TeacherAuthState>(
                builder: (context, state) {
                  // 1) Try to read data from authenticated state (if available)
                  if (state is TeacherAuthAuthenticated) {
                    final dynamic teacher = state.teacher;

                    // Safely extract first/last name if teacher is a Map-like structure
                    try {
                      if (teacher is Map) {
                        final firstName =
                            (teacher['firstName'] ?? '').toString();
                        final lastName = (teacher['lastName'] ?? '').toString();
                        final computed = ('$firstName $lastName').trim();
                        if (computed.isNotEmpty) {
                          teacherName = computed;
                        } else {
                          teacherName =
                              (teacher['emailId'] ??
                                      teacher['email'] ??
                                      'Teacher')
                                  .toString();
                        }

                        profilePicUrl ??= teacher['profilePicUrl']?.toString();
                        department ??= teacher['department']?.toString();
                      } else if (teacher is String) {
                        // attempt to decode JSON string
                        try {
                          final decoded = jsonDecode(teacher);
                          if (decoded is Map) {
                            final firstName =
                                (decoded['firstName'] ?? '').toString();
                            final lastName =
                                (decoded['lastName'] ?? '').toString();
                            final computed = ('$firstName $lastName').trim();
                            teacherName =
                                computed.isNotEmpty
                                    ? computed
                                    : (decoded['emailId'] ??
                                            decoded['email'] ??
                                            'Teacher')
                                        .toString();
                            profilePicUrl ??=
                                decoded['profilePicUrl']?.toString();
                            department ??= decoded['department']?.toString();
                          }
                        } catch (_) {
                          // ignore decode errors
                        }
                      }
                    } catch (_) {
                      // ignore parsing errors
                    }
                  }

                  // 2) Fallback to local storage if we still don't have a teacherName
                  if ((teacherName?.isEmpty ?? true) &&
                      GetStorage().hasData('teacher')) {
                    final stored = GetStorage().read('teacher');
                    try {
                      if (stored is Map) {
                        final firstName =
                            (stored['firstName'] ?? '').toString();
                        final lastName = (stored['lastName'] ?? '').toString();
                        final computed = ('$firstName $lastName').trim();
                        if (computed.isNotEmpty) {
                          teacherName = computed;
                        }
                        profilePicUrl ??= (stored['profilePicUrl'])?.toString();
                        department ??= stored['department']?.toString();
                      } else if (stored is String) {
                        final decoded = jsonDecode(stored);
                        if (decoded is Map) {
                          final firstName =
                              (decoded['firstName'] ?? '').toString();
                          final lastName =
                              (decoded['lastName'] ?? '').toString();
                          final computed = ('$firstName $lastName').trim();
                          if (computed.isNotEmpty) teacherName = computed;
                          profilePicUrl ??=
                              decoded['profilePicUrl']?.toString();
                          department ??= decoded['department']?.toString();
                        }
                      }
                    } catch (_) {
                      // ignore parsing errors
                    }
                  }

                  // Ensure we have a non-null name for display
                  final String displayName =
                      (teacherName?.isNotEmpty == true)
                          ? teacherName!
                          : 'Teacher';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                showTeacherSidebar(
                                  context,
                                  teacherName: displayName,
                                  designation: 'Faculty',
                                  photoUrl: profilePicUrl,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.wb_sunny_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getGreeting(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Prof. $displayName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Mathematics Department',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const NotificationsPage(),
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            'Students',
                             isLoadingStudents
                                ? '...'
                                : totalStudents.toString(),
                            Icons.people_outline,
                            Colors.blue,
                          ),
                          BlocBuilder<TeacherClassBloc, TeacherClassState>(
                            builder: (context, state) {
                              int classCount = 0;
                              if (state is TeacherClassLoaded) {
                                classCount = state.classes.where((c) => c.isActive).length;
                              }

                              return _buildStatCard(
                                'Classes',
                                classCount.toString(),
                                Icons.class_outlined,
                                Colors.purple,
                              );
                            },
                          ),
                          _buildStatCard(
                            'Avg Attendance',
                             isLoadingStudents
                                ? '...'
                                 : '${averageAttendance}%',
                            Icons.trending_up,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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
                        'Create\nClass',
                        Icons.add_circle_outline,
                        const Color(0xFF3B82F6),
                        () => _onItemTapped(1),
                      ),
                      _buildQuickAction(
                        'Download\nAttendance',
                        Icons.edit_outlined,
                        const Color(0xFF8B5CF6),
                        () {},
                      ),
                      _buildQuickAction(
                        'Notice\nBoard',
                        Icons.chat_bubble_outline,
                        const Color(0xFFF59E0B),
                        () {
                          // TODO: Navigate to chat page
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Column(
              children: [
                Container(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),

            // Today's Schedule
            BlocBuilder<TeacherClassBloc,TeacherClassState>(
                builder: (context, state){
                  if(state is TeacherClassLoading){
                    return const Center(child: CircularProgressIndicator(),);
                  }
                  if(state is TeacherClassLoaded){
                    final todayClasses = filterTodayClasses(state.classes);
                    if(todayClasses.isEmpty){
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'No classes scheduled for today.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    todayClasses.sort((a,b) => a.startTime.compareTo(b.startTime));
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          // 🔷 Class List using YOUR CARD
                          ...todayClasses.map((cls) {
                            final isActive =
                            isClassActive(cls.startTime, cls.endTime);

                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: _buildScheduleCard(
                                cls.className, // title
                                '${formatTime(cls.startTime)} - ${formatTime(cls.endTime)}', // time
                                cls.roomNo,
                                '${cls.students.length}',// teacher/room
                                isActive,
                                isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF3B82F6),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }
                  return SizedBox();

                }
                ),

            const SizedBox(height: 20),

            // This Week Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFEFF), // light cyan tint
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF06B6D4,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.book_outlined,
                                  color: Color(0xFF06B6D4),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$totalClasses',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Classes Held',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4), // light green tint
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF10B981),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '$averageAttendance%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Avg Attendance',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(isSelected ? -0.05 : 0) // 3D tilt
              ..translate(0.0, isSelected ? -8.0 : 0.0), // lift up
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: isSelected ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          borderRadius: BorderRadius.circular(18),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    // Inner highlight for 3D effect
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 2,
                      offset: const Offset(0, -1),
                    ),
                  ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        height: 112,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
                  color: color.withOpacity(0.3),
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
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    String title,
    String time,
    String room,
    String students,
    bool isActive,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: $room',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$students students',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
              icon: const Icon(Icons.co_present),
              color: color,
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  void navigate(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutBack;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}
