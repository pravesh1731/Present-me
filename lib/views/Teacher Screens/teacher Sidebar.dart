import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:present_me_flutter/views/common%20Page/Notes&PYQs/Notes&PYQ.dart';
import 'package:present_me_flutter/views/common%20Page/Notes&PYQs/downloaded_notes_screen.dart';
import 'package:present_me_flutter/views/common%20Page/Notes&PYQs/my_uploads_screen.dart';
import '../../components/common/Navigation.dart';
import '../Notice/teachers Notice classes.dart';
import '../../viewmodels/teacher_auth/teacher_auth_bloc.dart';
import '../Help & Support Page/help_support_page.dart';
import '../IntroScreen/introScreen.dart';
import '../Policy/privacy_policy.dart';
import '../Setting Page/settings_page.dart';
import 'create class.dart';
import 'downloadAttendance.dart';


// Teacher Sidebar / Drawer panel matching provided screenshot design.
// Usage: call showTeacherSidebar(context); to display.

void showTeacherSidebar(
  BuildContext context, {
  required String teacherName,
  required String designation,
  String? photoUrl,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      // Use a more natural spring-like curve
      final slideCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuart,
      );
      
      // Smooth slide from left
      final slide = Tween<Offset>(
        begin: const Offset(-1.0, 0),
        end: Offset.zero,
      ).animate(slideCurve);
      
      // Gentle fade that matches the slide timing
      final fadeInCurve = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      );
      
      return SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: fadeInCurve,
              child: _TeacherSidebar(
                teacherName: teacherName,
                designation:designation,
                photoUrl: photoUrl,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _TeacherSidebar extends StatelessWidget {
  final double panelWidth = 280; // reduced width from 320 to 270
  final String teacherName;
  final String designation;
  final String? photoUrl;
  const _TeacherSidebar({
    required this.teacherName,
    required this.designation,
    this.photoUrl,

  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: panelWidth,

        // Removed top margin to eliminate space above the sidebar
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _MenuItem(
                        icon: Icons.edit_note_outlined,
                        label: 'Fill Marks',
                        onTap:
                            () =>
                                placeholder(context, 'Fill Marks coming soon'),
                      ),
                      _MenuItem(
                        icon: Icons.download_outlined,
                        label: 'Download Attendance',
                        onTap:
                            () => pushSlide(context, DownloadAttendancePage()),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_none_outlined,
                        label: 'Notices',
                        onTap:
                            () => pushSlide(
                              context,
                              const TeacherNoticeClass(),
                            ),
                      ),
                      _MenuItem(
                        icon: Icons.note_alt_outlined,
                        label: 'Notes',
                        onTap:
                            () => pushSlide(
                          context,
                          const NotesPyqsScreen(),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.note_alt_outlined,
                        label: 'Donwloads',
                        onTap:
                            () => pushSlide(
                          context,
                          const DownloadedNotesScreen(),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.note_alt_outlined,
                        label: 'Uploads',
                        onTap:
                            () => pushSlide(
                          context,
                          const MyUploadsScreen(),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1),
                      ),

                      _MenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap:
                            () => pushSlide(context, SettingsPage()),
                      ),
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        onTap: () => pushSlide(context, HelpSupportPage()),
                      ),
                      const SizedBox(height: 30), // space for sticky logout
                    ],
                  ),
                ),
              ),
              _buildLogoutBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child:
                    photoUrl != null && photoUrl!.isNotEmpty
                        ? ClipOval(
                          child: Image.network(
                            photoUrl!,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        )
                        : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacherName.isNotEmpty ? '$teacherName' : 'Professor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                     designation.isNotEmpty ? designation : 'Teacher',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () async {
          final confirm = await _showLogoutConfirmation(context);

          if (confirm == true) {
            context.read<TeacherAuthBloc>().add(TeacherLogoutRequested());

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => introscreen()),
                  (route) => false,
            );
          }
        },

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: const [
              Icon(Icons.logout, color: Color(0xFFDC2626)),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Future<bool?> _showLogoutConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}


class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onTap(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            // const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
