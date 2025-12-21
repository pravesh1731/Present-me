import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/Help%20&%20Support%20Page/help_support_page.dart';
import 'package:present_me_flutter/IntroScreen/introScreen.dart';
import 'package:present_me_flutter/Policy/privacy_policy.dart';
import 'package:present_me_flutter/Setting%20Page/settings_page.dart';
import '../src/bloc/student_auth/auth_event.dart';
import '../src/bloc/student_auth/auth_bloc.dart';
import '../src/bloc/student_auth/auth_state.dart';

class StudentSidebar extends StatelessWidget {
  final String? name;
  final String? photoUrl;

  const StudentSidebar({Key? key, this.name, this.photoUrl}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header with gradient - make it reactive to AuthBloc
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                ),
              ),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {

                  // 1️⃣ Default values (shown if nothing else is found)
                  String displayName = name?.isNotEmpty == true ? name! : 'Student';
                  String? avatarUrl =
                  (photoUrl != null && photoUrl!.isNotEmpty) ? photoUrl : null;

                  // 2️⃣ If user is logged in
                  if (state is AuthAuthenticated) {
                    final student = state.student;

                    // Get name from API user data
                    if ((displayName == 'Student' || displayName.isEmpty)) {
                      final firstName = (student['firstName'] ?? '').toString();
                      final lastName = (student['lastName']  ?? '').toString();

                      final fullName = ('$firstName $lastName').trim();

                      if (fullName.isNotEmpty) {
                        displayName = fullName;
                      } else {
                        displayName =
                            (student['emailId'] ?? student['email'] ?? 'Student').toString();
                      }
                    }

                    // Get profile picture from API
                    avatarUrl ??= student['profilePicUrl']?.toString();
                  }

                  // 3️⃣ Fallback: Get data from local storage
                  if ((displayName == 'Student' || displayName.isEmpty) &&
                      GetStorage().hasData('student')) {

                    final stored = GetStorage().read('student');

                    if (stored is Map) {
                      final firstName =
                      (stored['firstName']  ?? '').toString();
                      final lastName =
                      (stored['lastName']  ?? '').toString();

                      final fullName = ('$firstName $lastName').trim();

                      if (fullName.isNotEmpty) {
                        displayName = fullName;
                      }

                      avatarUrl ??= (stored['profilePicUrl'])?.toString();
                    }
                  }

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Menu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildUserProfile(name: displayName, photoUrl: avatarUrl),
                    ],
                  );
                },
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notices',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to notices
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.emoji_events_outlined,
                    label: 'Scores',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to scores
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    label: 'Doubts',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to doubts
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.note_outlined,
                    label: 'Notes',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to notes
                    },
                  ),
                  const Divider(height: 32, thickness: 1, indent: 20, endIndent: 20),

                  _buildMenuItem(
                    context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpSupportPage()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    label: 'Privacy Policy',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Container(
              padding: const EdgeInsets.all(20),
              child: InkWell(
                onTap: () async {
                 context.read<AuthBloc>().add(LogoutRequested());
                 
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => introscreen()),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red.shade700, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildUserProfile({required String name, String? photoUrl}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color.fromRGBO(255, 255, 255, 0.3),
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')))
              ? NetworkImage(photoUrl)
              : const AssetImage("assets/image/teacher.png") as ImageProvider,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              const Text(
                'Student',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF1F2937),
        size: 22,
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      horizontalTitleGap: 16,
    );
  }
}

// Function to show the sidebar
void showStudentSidebar(BuildContext context, {String? name, String? photoUrl}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerLeft,
        child: StudentSidebar(name: name, photoUrl: photoUrl),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    },
  );
}
