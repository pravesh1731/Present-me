import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../smart%20attendance%20main.dart';

class SmartAttendanceClasses extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get all the classes of the logged-in teacher
  Stream<List<Map<String, dynamic>>> _getClassesStream() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return Stream.empty(); // If no user is logged in, return an empty stream

    // Query Firestore to get the classes created by the logged-in teacher
    return _firestore
        .collection('classes')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'code': doc['code'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFEFF),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 42, bottom: 24, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF06B6D4), // cyan-500
                  Color(0xFF2563EB), // blue-600
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
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
                    padding: const EdgeInsets.only(top: 8.0),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [


                          const Text(
                            'Smart Attendance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select a class to mark attendance',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getClassesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF9F5FFF))));
              }
              if (snapshot.hasError) {
                return const Expanded(child: Center(child: Text('Error loading classes')));
              }
              final classes = snapshot.data ?? [];
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 2),
                      child: Text(
                        'Active Classes (${classes.length})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      child: classes.isEmpty
                          ? const Center(child: Text('No classes found', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: classes.length,
                              itemBuilder: (context, index) {
                                final classItem = classes[index];
                                final attendance = [94, 89, 91, 88][index % 4];
                                final students = [35, 28, 30, 32][index % 4];
                                final topBorderColors = [
                                  Color(0xFF10B981), // green
                                  Color(0xFFF59E0B), // orange
                                  Color(0xFF10B981), // green
                                  Color(0xFF6366F1), // indigo
                                ];
                                final iconColors = [
                                  Color(0xFF10B981),
                                  Color(0xFFF59E0B),
                                  Color(0xFF10B981),
                                  Color(0xFF6366F1),
                                ];
                                final icons = [
                                  Icons.menu_book_outlined,
                                  Icons.menu_book_outlined,
                                  Icons.menu_book_outlined,
                                  Icons.menu_book_outlined,
                                ];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(milliseconds: 500),
                                        pageBuilder: (_, __, ___) => SmartAttendanceTeacherPage(
                                          className: classItem['name']!,
                                          classCode: classItem['code']!,
                                        ),
                                        transitionsBuilder: (_, animation, __, child) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.easeInOutBack;
                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                          var offsetAnimation = animation.drive(tween);
                                          return SlideTransition(
                                            position: offsetAnimation,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.07),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                      border: Border(
                                        top: BorderSide(
                                          color: topBorderColors[index % topBorderColors.length],
                                          width: 5,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFECFEFF),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: Icon(
                                              icons[index % icons.length],
                                              color: iconColors[index % iconColors.length],
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  classItem['name']!,
                                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Code: ${classItem['code']}',
                                                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF6B7280)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '$students students',
                                                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: attendance >= 90 ? Color(0xFF10B981) : Color(0xFFF59E0B),
                                                        borderRadius: BorderRadius.circular(999),
                                                      ),
                                                      child: Text(
                                                        '$attendance%',
                                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
