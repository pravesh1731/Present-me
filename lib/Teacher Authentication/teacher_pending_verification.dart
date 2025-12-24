import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/Teacher%20Authentication/teacher%20login%20screen.dart';

class TeacherPendingVerification extends StatelessWidget {
  final String? email;
  const TeacherPendingVerification({Key? key, this.email}) : super(key: key);

  Widget _buildStatusItem({
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(2, 6, 23, 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 6)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = 820.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEBF8FF), Color(0xFFF8FBFF)],
          ),
        ),
        child: Stack(
          children: [
            // decorative circles
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.yellow.shade600.withOpacity(0.25), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              right: -100,
              bottom: -120,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.purple.shade200.withOpacity(0.12), Colors.transparent]),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // animated top badge
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.85, end: 1.0),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: const Color.fromRGBO(255, 213, 79, 0.18), blurRadius: 24, offset: const Offset(0, 10)),
                              ],
                            ),
                            child: const Center(child: Icon(Icons.hourglass_top, color: Colors.white, size: 36)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          'Account Pending Verification',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0B1726)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Thanks for registering — we are reviewing your request.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF586171)),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 26),

                        // Glass card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.6)),
                                boxShadow: [
                                  BoxShadow(color: const Color.fromRGBO(2, 6, 23, 0.05), blurRadius: 30, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // subtle header
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7FFF6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Registration Submitted', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  ),

                                  const SizedBox(height: 14),

                                  // success banner
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFFBF0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Color(0xFF2F9E44)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            email != null && email!.isNotEmpty
                                                ? 'A confirmation has been sent to $email and your request is under review.'
                                                : 'Your account request has been successfully submitted and is under review.',
                                            style: const TextStyle(color: Color(0xFF2F9E44), fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // status list
                                  Column(
                                    children: [
                                      _buildStatusItem(
                                        accent: const Color(0xFF7C3AED),
                                        icon: Icons.email_outlined,
                                        title: 'Confirmation Email Sent',
                                        subtitle: email != null && email!.isNotEmpty
                                            ? 'We\'ve sent a confirmation to $email.'
                                            : 'We\'ve sent a confirmation email.' ,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildStatusItem(
                                        accent: const Color(0xFFF59E0B),
                                        icon: Icons.hourglass_bottom,
                                        title: 'Verification in Progress',
                                        subtitle: 'Your account is being reviewed by your Admin .',
                                        trailing: SizedBox(
                                          width: 36,
                                          height: 36,

                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildStatusItem(
                                        accent: const Color(0xFF6D28D9),
                                        icon: Icons.headset_mic_outlined,
                                        title: 'We Will Contact You Soon',
                                        subtitle: 'Once verified you\'ll receive an email with login instructions.',
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 18),
                                  const Divider(),
                                  const SizedBox(height: 12),

                                  const Text('What happens next?', style: TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text('• Our admin team will review your application and verify your credentials.', style: TextStyle(color: Colors.grey.shade700)),
                                  const SizedBox(height: 6),
                                  Text('• You\'ll receive an email notification once your account is approved.', style: TextStyle(color: Colors.grey.shade700)),
                                  const SizedBox(height: 6),
                                  Text('• Use your credentials to log in to the admin panel.', style: TextStyle(color: Colors.grey.shade700)),

                                  const SizedBox(height: 18),

                                  // actions
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            // navigate back to login
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => teacherLogin()));
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            backgroundColor: const Color(0xFF0EA5E9),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 4,
                                          ),
                                          child: const Text('Back to Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () {
                                          // perhaps open mail app or support screen
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFF6D28D9)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        ),
                                        child: const Icon(Icons.support_agent, color: Color(0xFF6D28D9)),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  Center(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Need help or have questions? ',
                                        style: TextStyle(color: Colors.grey.shade700),
                                        children: [
                                          TextSpan(
                                            text: 'Contact Support',
                                            style: const TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                // handle contact support
                                              },
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),
                        Text('© ${DateTime.now().year} Present-Me. All rights reserved.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

