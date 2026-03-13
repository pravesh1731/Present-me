import 'package:flutter/material.dart';

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40,bottom: 24, left: 24, right: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:  [

                          Text(
                            'Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          Text(
                            'Manage your app preferences',
                            style: TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Notifications Section
              _sectionTitle('Notifications'),
              _settingsCard(
                icon: Icons.notifications_active_rounded,
                iconColor: Color(0xFF6366F1),
                title: 'Push Notifications',
                subtitle: 'Receive app notifications',
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
              // Appearance Section
              _sectionTitle('Appearance'),
              _settingsCard(
                icon: Icons.nightlight_round,
                iconColor: Color(0xFF8B5CF6),
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
              _settingsCard(
                icon: Icons.language,
                iconColor: Color(0xFFF59E0B),
                title: 'Language',
                subtitle: 'English (US)',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF9CA3AF)),
              ),
              // Privacy & Security Section
              _sectionTitle('Privacy & Security'),
              _settingsCard(
                icon: Icons.lock_rounded,
                iconColor: Color(0xFF10B981),
                title: 'Change Password',
                subtitle: 'Update your password',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF9CA3AF)),
              ),
              _settingsCard(
                icon: Icons.remove_red_eye_rounded,
                iconColor: Color(0xFF06B6D4),
                title: 'Face ID',
                subtitle: 'Use biometric authentication',
                trailing: Switch(value: false, onChanged: (_) {}),
              ),
              _settingsCard(
                icon: Icons.privacy_tip_rounded,
                iconColor: Color(0xFF8B5CF6),
                title: 'Privacy Policy',
                subtitle: 'View privacy policy',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF9CA3AF)),
              ),
              // Data & Storage Section
              _sectionTitle('Data & Storage'),
              _settingsCard(
                icon: Icons.backup_rounded,
                iconColor: Color(0xFFF472B6),
                title: 'Auto Backup',
                subtitle: 'Backup data automatically',
                trailing: Switch(value: true, onChanged: (_) {}),
              ),
              _settingsCard(
                icon: Icons.data_usage_rounded,
                iconColor: Color(0xFF06B6D4),
                title: 'Cache Size',
                subtitle: '24.5 MB',
                trailing: TextButton(
                  onPressed: () {},
                  child: const Text('Clear', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
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
                    Text('Present-Me', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF374151))),
                    SizedBox(height: 8),
                    Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
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
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
