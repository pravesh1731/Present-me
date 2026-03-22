import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import 'package:present_me_flutter/mark%20smart%20attendance%20main.dart';
import 'package:present_me_flutter/viewmodels/student_class/student_class_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/studentClass.dart';


class mark_Smart_Attendance extends StatefulWidget {
  const mark_Smart_Attendance({super.key});

  @override
  State<mark_Smart_Attendance> createState() => _MarkSmartAttendanceState();
}

class _MarkSmartAttendanceState extends State<mark_Smart_Attendance> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final token = getToken();
        if (token.isNotEmpty) {
          context.read<StudentClassBloc>().add(
            StudentFetchEnrolledClasses(token),
          );
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Header(
            heading: "Mark Attendance",
            subheading: "Select a class to mark your attendance",
          ),
          Expanded(
            // ← Bug 1 fix
            child: BlocBuilder<StudentClassBloc, StudentClassState>(
              builder: (context, state) {
                if (state is StudentClassLoading) {
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      const SizedBox(height: 8),
                      _buildShimmerCard(),
                      _buildShimmerCard(),
                      _buildShimmerCard(),
                      _buildShimmerCard(),
                    ],
                  );
                }

                if (state is StudentClassError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            final token = getToken();
                            if (token.isNotEmpty) {
                              context.read<StudentClassBloc>().add(
                                StudentFetchEnrolledClasses(token),
                              );
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is StudentClassLoaded) {
                  if (state.classes.isEmpty) {
                    return const Center(
                      child: Text(
                        "You are not enrolled in any classes yet.",
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: state.classes.length, // ← Bug 2 fix: no +1
                    itemBuilder: (context, index) {
                      final cls = state.classes[index]; // ← Bug 2 fix: no -1
                      return _buildClassCard(cls, context);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildClassCard(StudentClassModel cls, BuildContext context) {
  final Color primary =
      classColors[(cls.classCode.hashCode) % classColors.length];
  final Color secondary =
      classColors[(cls.classCode.hashCode + 1) % classColors.length];

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SmartAttendanceStudentPage(
                className: cls.className,
                classCode: cls.classCode,
              ),
        ),
      );
    },
    child: Container(
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [_soften(primary, 0.28), _soften(secondary, 0.28)],
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
                        color: _tint(primary, 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primary.withOpacity(0.18)),
                      ),
                      child: Icon(Icons.menu_book_outlined, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cls.className,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Prof. ${cls.teacherName}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
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
                    Text(
                      '${cls.startTime} -',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cls.endTime,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.room_outlined,
                      size: 16,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Room: ${cls.roomNo}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCodeBadge(cls.classCode, primary),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Color _tint(Color color, double amount) =>
    Color.lerp(color, Colors.white, amount) ?? color;

Color _soften(Color color, double amount) =>
    Color.lerp(color, Colors.white, amount) ?? color;

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
          style: TextStyle(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget _buildShimmerCard() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    child: Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Container(width: 100, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: 160, height: 14, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: 100, height: 14, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

const List<Color> classColors = [
  Color(0xFF10B981),
  Color(0xFF059669),
  Color(0xFF6366F1),
  Color(0xFF4F46E5),
  Color(0xFF8B5CF6),
  Color(0xFF7C3AED),
  Color(0xFFF59E0B),
  Color(0xFFD97706),
  Color(0xFFEF4444),
  Color(0xFFDC2626),
  Color(0xFF14B8A6),
  Color(0xFF0D9488),
  Color(0xFF06B6D4),
  Color(0xFF0891B2),
  Color(0xFFA855F7),
  Color(0xFF9333EA),
  Color(0xFF3B82F6),
  Color(0xFF2563EB),
  Color(0xFFF97316),
  Color(0xFFEA580C),
];
