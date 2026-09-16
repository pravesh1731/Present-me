import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/common/Button/button.dart';
import '../../core/widgets/header.dart';
import '../Policy/privacy_policy.dart';
import '../Student Screens/ChangePasswordScreen.dart';

_showDeleteConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Account?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'This will permanently delete your account and all associated data within 30 days. This action cannot be undone.',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Open delete account web page
                launchUrl(Uri.parse('https://presentme.in/delete_account'));
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
  );
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient Header
              Header(
                heading: "Settings",
                subheading: "Manage your app preferences",
              ),

              // Appearance Section
              _sectionTitle('Appearance'),
              _settingsCard(
                icon: Icons.nightlight_round,
                iconColor: Color(0xFF8B5CF6),
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                trailing: Switch(
                  value: false,
                  onChanged: (_) {
                    Fluttertoast.showToast(
                      msg: "Dark mode coming soon!",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );
                  },
                ),
              ),
              GestureDetector(
                onTap: () {
                  Fluttertoast.showToast(
                    msg: "Language settings coming soon!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                },
                child: _settingsCard(
                  icon: Icons.language,
                  iconColor: Color(0xFFF59E0B),
                  title: 'Language',
                  subtitle: 'English (US)',
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              // Privacy & Security Section
              _sectionTitle('Privacy & Security'),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordScreen(),
                    ),
                  );
                },
                child: _settingsCard(
                  icon: Icons.lock_rounded,
                  iconColor: Color(0xFF10B981),
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivacyPolicyPage(),
                    ),
                  );
                },
                child: _settingsCard(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: Color(0xFF8B5CF6),
                  title: 'Privacy Policy',
                  subtitle: 'View privacy policy',
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),

              // App Info Card
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Text(
                      'Present-Me',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Button(
                  text: "Delete Account",
                  onPressed: () => _showDeleteConfirmation(context),
                  gradientColors: [
                    Color(0xFF5A0000),
                    Color(0xFFB00020)
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
