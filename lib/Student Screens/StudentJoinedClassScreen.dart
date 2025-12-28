import 'package:flutter/material.dart';

class StudentJoinedClassScreen extends StatefulWidget {
  const StudentJoinedClassScreen({Key? key}) : super(key: key);

  @override
  State<StudentJoinedClassScreen> createState() => _StudentJoinedClassScreenState();
}

class _StudentJoinedClassScreenState extends State<StudentJoinedClassScreen> {
  bool _isLoading = false; // simulate loading if needed

  final List<Map<String, dynamic>> _requests = [
    {
      'name': 'Mathematics',
      'teacher': 'Mrs. Smith',
      'room': 'Room 301',
      'timeAgo': '2 hours ago',
      'status': 'Pending',
      'colorIndex': 0,
      'message': "Your request is waiting for teacher approval. You'll be notified once it's reviewed.",
    },
    {
      'name': 'Physics',
      'teacher': 'Mr. Johnson',
      'room': 'Room 205',
      'timeAgo': '5 hours ago',
      'status': 'Pending',
      'colorIndex': 2,
      'message': "Your request is waiting for teacher approval. You'll be notified once it's reviewed.",
    },
  ];

  static const List<List<Color>> _themes = [
    [Color(0xFF3B82F6), Color(0xFF2563EB)], // blue
    [Color(0xFFF97316), Color(0xFFF43F5E)], // orange/red
    [Color(0xFFA855F7), Color(0xFF7C3AED)], // purple
    [Color(0xFF06B6D4), Color(0xFF0891B2)], // cyan
    [Color(0xFF10B981), Color(0xFF059669)], // emerald
  ];

  void _onCancelRequest(int index) {
    // simple local removal to simulate cancel
    setState(() {
      _requests.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Request cancelled'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),

              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _requests.isEmpty
                        ? _buildNoClasses()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _requests.length + 1,
                            itemBuilder: (context, idx) {
                              if (idx == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Text(
                                    'Awaiting Teacher Approval',
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              final index = idx - 1;
                              final r = _requests[index];
                              final theme = _themes[r['colorIndex'] % _themes.length];
                              return _buildRequestCard(index, r, theme);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 22),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // Colors.white.withOpacity(0.12) -> preserve alpha via fromRGBO
                color: const Color.fromRGBO(255, 255, 255, 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 2),
                Text(
                  'Pending Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Classes awaiting approval',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }



  Widget _buildRequestCard(int index, Map<String, dynamic> r, List<Color> theme) {
    final primary = theme[0];
    final secondary = theme[1];
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              // top colored stripe with matching curved corners
              Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, secondary]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            // primary.withOpacity(0.12) -> construct with fromRGBO
                            color: Color.fromRGBO(primary.red, primary.green, primary.blue, 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.menu_book_outlined, color: primary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      r['name'] ?? '',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withOpacity(.2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      r['status'] ?? 'Pending',
                                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r['teacher'] ?? '',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 8),
                            Text(r['room'] ?? '', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                          ],
                        ),
                        const SizedBox(width: 18),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 8),
                            Text(r['timeAgo'] ?? '', style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // message box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE1D2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            // padding: const EdgeInsets.all(8),

                            child: Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r['message'] ?? '',
                              style: TextStyle(color: Colors.orange[900], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // cancel button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _onCancelRequest(index),
                        icon: const Icon(Icons.close, size: 18,color: Colors.white),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC1E1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
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

  Widget _buildNoClasses() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF2563EB)]),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.class_, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('No classes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('You have not requested to join any classes yet.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
