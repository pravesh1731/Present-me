import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class joined_Class extends StatefulWidget {
  @override
  State<joined_Class> createState() => _joined_ClassState();
}

class _joined_ClassState extends State<joined_Class> {
  final TextEditingController _codeController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // Palette: [primary, secondary] per class theme
  static const List<List<Color>> _classThemes = [
    [Color(0xFF10B981), Color(0xFF059669)], // emerald
    [Color(0xFF6366F1), Color(0xFF4F46E5)], // indigo
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // violet
    [Color(0xFFF59E0B), Color(0xFFD97706)], // amber
    [Color(0xFFEF4444), Color(0xFFDC2626)], // red
    [Color(0xFF14B8A6), Color(0xFF0D9488)], // teal
    [Color(0xFF06B6D4), Color(0xFF0891B2)], // cyan
    [Color(0xFFA855F7), Color(0xFF9333EA)], // purple
    [Color(0xFF3B82F6), Color(0xFF2563EB)], // blue
    [Color(0xFFF97316), Color(0xFFEA580C)], // orange
  ];

  void _joinClass(String code) async {
    if (currentUser == null) return;

    final classDocRef = FirebaseFirestore.instance.collection('classes').doc(code);

    try {
      final classSnapshot = await classDocRef.get();

      if (!classSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text("Class code not found"),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final classData = classSnapshot.data()!;
      final userId = currentUser!.uid;

      final List<dynamic> joinedStudents = classData['students'] ?? [];
      if (joinedStudents.contains(userId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text("You have already joined this class"),
              ],
            ),
            backgroundColor: const Color(0xFF6B7280),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final List<dynamic> joinRequests = classData['joinRequests'] ?? [];
      final alreadyRequested = joinRequests.any((req) => req['uid'] == userId);
      if (alreadyRequested) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.pending_outlined, color: Colors.white),
                SizedBox(width: 12),
                Text("You have already requested to join this class"),
              ],
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .get();

      final studentData = {
        'uid': userId,
        'name': studentSnapshot['name'] ?? '',
        'rollNo': studentSnapshot['roll'] ?? '',
      };

      await classDocRef.update({
        'joinRequests': FieldValue.arrayUnion([studentData]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Request sent. Wait for teacher approval."),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("Error: $e")),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showJoinClassDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        elevation: 24,
        child: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                padding: const EdgeInsets.fromLTRB(28, 28, 20, 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 18),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Class',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Enter the class code to join',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _codeController.clear();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.key_rounded, color: Colors.teal.shade600, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              '6-Digit Class Code',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 2),
                          decoration: InputDecoration(
                            hintText: 'Enter 6-digit code',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            filled: true,
                            fillColor: Colors.white,
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) {
                            // Only allow digits
                            if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                              _codeController.text = value.replaceAll(RegExp(r'[^0-9]'), '');
                              _codeController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _codeController.text.length),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        // Join Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final code = _codeController.text.trim();
                                
                                if (code.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.warning_rounded, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text('Please enter class code'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                  return;
                                }
                                
                                if (code.length != 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.warning_rounded, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text('Class code must be exactly 6 digits'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                  return;
                                }
                                
                                if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.warning_rounded, color: Colors.white),
                                          SizedBox(width: 12),
                                          Text('Class code must contain only digits'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                  return;
                                }
                                
                                _joinClass(code);
                                _codeController.clear();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.login_rounded, color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Join Class',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }

  // Tab controller for Active/Inactive
  int _selectedTab = 0; // 0: Active, 1: Inactive

  // Store inactive class codes locally (simulate moving to inactive)
  List<String> _inactiveClassCodes = [];

  Stream<List<Map<String, dynamic>>> _getJoinedClassesStream() {
    return FirebaseFirestore.instance.collection('classes').snapshots().map((snapshot) {
      final userUid = currentUser?.uid;
      if (userUid == null) return [];

      final List<Map<String, dynamic>> userClasses = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final students = List<String>.from(data['students'] ?? []);
        if (students.contains(userUid)) {
          userClasses.add({
            'name': data['name'] ?? 'Untitled Class',
            'code': doc.id,
            'room': data['room'] ?? '',
            'startTime': data['startTime'] ?? '',
            'endTime': data['endTime'] ?? '',
            'days': data['days'] ?? [],
          });
        }
      }

      return userClasses;
    });
  }

  List<Map<String, dynamic>> _filterActiveClasses(List<Map<String, dynamic>> classes) {
    return classes.where((c) => !_inactiveClassCodes.contains(c['code'])).toList();
  }
  List<Map<String, dynamic>> _filterInactiveClasses(List<Map<String, dynamic>> classes) {
    return classes.where((c) => _inactiveClassCodes.contains(c['code'])).toList();
  }

  void _moveToInactive(String code) {
    setState(() {
      if (!_inactiveClassCodes.contains(code)) {
        _inactiveClassCodes.add(code);
      }
    });
  }
  void _moveToActive(String code) {
    setState(() {
      _inactiveClassCodes.remove(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinClassDialog,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Join Class',
      ),
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getJoinedClassesStream(),
            builder: (context, snapshot) {
              final classes = snapshot.data ?? [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading classes'));
              }

              // Tab bar
              return Column(
                children: [
                  _buildHeader(classes.length),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color:  Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withOpacity(0.10),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_filterActiveClasses(classes).length}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withOpacity(0.10),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Inactive',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_filterInactiveClasses(classes).length}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (classes.isEmpty) {
                          return _buildEmptyState();
                        }
                        final showClasses = _selectedTab == 0
                            ? _filterActiveClasses(classes)
                            : _filterInactiveClasses(classes);
                        if (showClasses.isEmpty) {
                          return Center(
                            child: Text(
                              _selectedTab == 0
                                  ? 'No Active Classes'
                                  : 'No Inactive Classes',
                              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: showClasses.length,
                          itemBuilder: (context, index) {
                            final c = showClasses[index];
                            final theme = _classThemes[index % _classThemes.length];
                            return Stack(
                              children: [
                                _buildClassCard(
                                  context,
                                  name: c['name'] ?? 'Class',
                                  code: c['code'] ?? '--',
                                  dayBadges: List<String>.from(c['days'] ?? []),
                                  timeLabel: _formatTime(c['startTime'], c['endTime']),
                                  roomLabel: c['room']?.isNotEmpty == true ? 'Room ${c['room']}' : 'No room',
                                  primary: theme[0],
                                  secondary: theme[1],
                                ),
                                Positioned(
                                  top: 10,
                                  right: 18,
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (value) {
                                      if (value == 'move') {
                                        if (_selectedTab == 0) {
                                          _moveToInactive(c['code']);
                                        } else {
                                          _moveToActive(c['code']);
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: 'move',
                                        child: Row(
                                          children: [
                                            Icon(
                                              _selectedTab == 0 ? Icons.remove_circle_outline : Icons.check_circle_rounded,
                                              color: _selectedTab == 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(_selectedTab == 0 ? 'Move to Inactive' : 'Move to Active',
                                              style: TextStyle(
                                                color: _selectedTab == 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.fromLTRB(20, 44, 16, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Classes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$activeCount joined classes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF06B6D4).withOpacity(0.1),
                  const Color(0xFF2563EB).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 80,
              color: const Color(0xFF06B6D4).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Classes Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You haven't joined any classes yet.\nTap the + button to join a class.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context, {
    required String name,
    required String code,
    required List<String> dayBadges,
    required String timeLabel,
    required String roomLabel,
    required Color primary,
    required Color secondary,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top accent bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [_soften(primary, 0.30), _soften(secondary, 0.30)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_tint(primary, 0.95), _tint(primary, 0.90)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withOpacity(0.18)),
                      ),
                      child: Icon(Icons.menu_book_outlined, color: secondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: dayBadges.isNotEmpty
                                ? dayBadges.map((d) => _buildBadge(d)).toList()
                                : [_buildBadge('No days set')],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(timeLabel, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.room_outlined, size: 16, color: Colors.black45),
                    const SizedBox(width: 6),
                    Text(roomLabel, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCodeBadge(code, primary),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCodeBadge(String code, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _tint(primary, 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.key_rounded, size: 14, color: primary),
          const SizedBox(width: 4),
          Text(
            code,
            style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Color _tint(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  Color _soften(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount) ?? color;
  }

  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null || startTime.isEmpty || endTime == null || endTime.isEmpty) {
      return 'Time not set';
    }
    return '$startTime - $endTime';
  }
}
