import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:present_me_flutter/components/common/Button/button.dart';
import 'package:present_me_flutter/Student%20Authentication/student%20login%20screen.dart';
import 'package:present_me_flutter/Teacher%20Authentication/teacher%20login%20screen.dart';

class introscreen extends StatelessWidget {
  const introscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 24,left: 25, top:50),
                child: Column(
                  children: [
                    // Header with icon
                    Logo(),
                    const SizedBox(height: 4),
        
                    // Title
                    const Text(
                      'Present-Me',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
        
                    // Subtitle
                    const Text(
                      'Smart Attendance Management System',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
        
                    // Choose Your Role
                    const Text(
                      'Choose Your Role',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
        
                    const Text(
                      'Select how you will be using Present-Me',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
        
                    // Student Card
                    _buildRoleCard(
                      context: context,
                      icon: Icons.school_outlined,
                      iconGradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF9333EA),],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      title: 'I\'m a Student',
                      subtitle: 'Track attendance, view\nscores, and manage\nyour classes',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => studentlogin()),
                      ),
                    ),
                    const SizedBox(height: 16),
        
                    // Teacher Card
                    _buildRoleCard(
                      context: context,
                      icon: Icons.groups_outlined,
                      iconGradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF0D9488),],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      title: 'I\'m a Teacher',
                      subtitle: 'Create classes, mark\nattendance, and\nmanage students',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => teacherLogin()),
                      ),
                    ),
                    const SizedBox(height: 70),

        
                    // Footer links
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                          const Text('  •  ', style: TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: const Text(
                        '© 2025 Present-Me  •  Developed by Jaanhvi',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required IconData icon,
    required Gradient iconGradient,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: iconGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon with white background
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconGradient.colors.first,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


