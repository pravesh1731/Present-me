import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/manual%20attendance%20classes%20screen.dart';
import 'package:present_me_flutter/smart%20attendance%20classes.dart';

class takeAttendnace extends StatefulWidget {
  @override
  State<takeAttendnace> createState() => _takeAttendnaceState();
}

class _takeAttendnaceState extends State<takeAttendnace> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
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
              // Header Section
              Container(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)], // cyan-500 to blue-600
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button and title
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Attendance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage student presence',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Mark Attendance Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mark Attendance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose an attendance marking method',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Manual Attendance Card
                      _buildAttendanceMethodCard(
                        context: context,
                        index: 0,
                        title: 'Manual Attendance',
                        subtitle: 'Mark attendance manually for each student',
                        icon: Icons.edit_calendar_outlined,
                        backgroundColor: const Color(0xFF06B6D4),
                        accentColor: const Color(0xFF0891B2),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 500),
                              pageBuilder: (_, __, ___) => ManualAttendanceClasses(),
                              transitionsBuilder: (_, animation, __, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutBack;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(position: offsetAnimation, child: child);
                              },
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Smart Attendance Card
                      _buildAttendanceMethodCard(
                        context: context,
                        index: 1,
                        title: 'Smart Attendance',
                        subtitle: 'Use Hotspot/wi-fi device detection',
                        icon: Icons.wifi_tethering_rounded,
                        backgroundColor: const Color(0xFF8B5CF6),
                        accentColor: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 500),
                              pageBuilder: (_, __, ___) => SmartAttendanceClasses(),
                              transitionsBuilder: (_, animation, __, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutBack;
                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(position: offsetAnimation, child: child);
                              },
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Video Attendance Card
                      _buildAttendanceMethodCard(
                        context: context,
                        index: 2,
                        title: 'Video Attendance',
                        subtitle: 'Use face recognition technology',
                        icon: Icons.face_retouching_natural,
                        backgroundColor: const Color(0xFF10B981),
                        accentColor: const Color(0xFF059669),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Video Attendance coming soon!')),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Today's Summary Section
                      const Text(
                        "Today's Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Summary Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Classes',
                              value: '4',
                              color: const Color(0xFF3B82F6), // blue
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Present',
                              value: '53',
                              color: const Color(0xFF10B981), // green
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Absent',
                              value: '7',
                              color: const Color(0xFFEF4444), // red
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceMethodCard({
    required BuildContext context,
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredIndex == index;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _hoveredIndex = index);
        _animationController.forward();
      },
      onTapUp: (_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() => _hoveredIndex = null);
          _animationController.reverse();
          onTap();
        });
      },
      onTapCancel: () {
        setState(() => _hoveredIndex = null);
        _animationController.reverse();
      },
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, isHovered ? -4.0 : 0.0)
          ..scale(isHovered ? 1.02 : 1.0),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(isHovered ? 0.5 : 0.3),
                blurRadius: isHovered ? 30 : 20,
                offset: Offset(0, isHovered ? 15 : 10),
                spreadRadius: isHovered ? 2 : 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Animated gradient background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHovered
                          ? [accentColor, backgroundColor]
                          : [backgroundColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                
                // Animated shine effect
                if (isHovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.0),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                
                // Decorative elements
                Positioned(
                  right: -30,
                  top: -30,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isHovered ? 0.2 : 0.1,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: -20,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isHovered ? 0.15 : 0.07,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      // Icon container with glassmorphism
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isHovered ? 0.25 : 0.2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isHovered ? 0.25 : 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}