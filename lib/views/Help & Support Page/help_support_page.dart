import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
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
                  padding: const EdgeInsets.only(top: 44, bottom: 24, left: 24, right: 24),
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
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Help & Support',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const Text(
                              'We\'re here to help you',
                              style: TextStyle(color: Colors.white70, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Quick Actions Title
                _sectionTitle('Quick Actions'),
                // Quick Actions Cards
                _quickActionCard(
                  color: Color(0xFF2563EB),
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Chat with Customer Care',
                  subtitle: 'Get instant help from our support team',
                  onTap: () {},
                ),
                _quickActionCard(
                  color: Color(0xFF8B5CF6),
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'support@present-me.com',
                  onTap: () {},
                ),
                _quickActionCard(
                  color: Color(0xFF10B981),
                  icon: Icons.call_outlined,
                  title: 'Call Us',
                  subtitle: '+1 (555) 123-4567',
                  onTap: () {},
                ),
                const SizedBox(height: 18),
                // Common Problems Title
                _sectionTitle('Common Problems'),
                // Common Problems Cards
                _problemCard(
                  color: Color(0xFF10B981),
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Attendance Problems',
                  subtitle: '8 articles',
                  onTap: () {},
                ),
                _problemCard(
                  color: Color(0xFF8B5CF6),
                  icon: Icons.class_outlined,
                  title: 'Class Management',
                  subtitle: '6 articles',
                  onTap: () {},
                ),
                _problemCard(
                  color: Color(0xFFF59E0B),
                  icon: Icons.payments_outlined,
                  title: 'Payment & Billing',
                  subtitle: '4 articles',
                  onTap: () {},
                ),
                _problemCard(
                  color: Color(0xFFEF4444),
                  icon: Icons.error_outline_rounded,
                  title: 'Technical Issues',
                  subtitle: '10 articles',
                  onTap: () {},
                ),
                const SizedBox(height: 18),
                // FAQ Section
                _sectionTitle('Frequently Asked Questions'),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                    children: [
                      _faqTile('How do I mark my attendance?'),
                      _faqTile('How to reset my password?'),
                      _faqTile('How to join a new class?'),
                      _faqTile('How to contact my teacher?'),
                      _faqTile('How to view my attendance history?'),
                    ],
                  ),
                ),
                // Support Hours Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Support Hours', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF374151))),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Monday - Friday', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                          Text('9:00 AM - 6:00 PM', style: TextStyle(color: Color(0xFF374151), fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Saturday', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                          Text('10:00 AM - 4:00 PM', style: TextStyle(color: Color(0xFF374151), fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sunday', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                          Text('Closed', style: TextStyle(color: Color(0xFF374151), fontSize: 14)),
                        ],
                      ),
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

  Widget _faqTile(String question) {
    return Column(
      children: [
        ListTile(
          title: Text(question, style: const TextStyle(fontSize: 15, color: Color(0xFF374151))),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF9CA3AF)),
          onTap: () {},
        ),
        const Divider(height: 1, thickness: 0.7, indent: 16, endIndent: 16, color: Color(0xFFF3F4F6)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 0, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF111827)),
      ),
    );
  }

  Widget _quickActionCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
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
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _problemCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.09),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border(
            top: BorderSide(color: color, width: 3.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
