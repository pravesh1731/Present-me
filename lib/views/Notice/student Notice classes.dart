import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import 'package:present_me_flutter/views/Notice/student%20Notiice%20main.dart';
import 'package:present_me_flutter/viewmodels/student_class/student_class_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/constants.dart';
import '../../../../models/studentClass.dart';

class StudentNoticeClass extends StatefulWidget {
  const StudentNoticeClass({super.key});

  @override
  State<StudentNoticeClass> createState() => _StudentNoticeClassState();
}

class _StudentNoticeClassState extends State<StudentNoticeClass>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _unseenCounts = {};

  // General notices state
  List<Map<String, dynamic>> _generalNotices = [];
  bool _isGeneralLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchClasses();
      _fetchGeneralNotices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchClasses() {
    try {
      final token = getToken();
      if (token.isNotEmpty) {
        context
            .read<StudentClassBloc>()
            .add(StudentFetchEnrolledClasses(token));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ─── Fetch general notices from admin ─────────────────────────────
  Future<void> _fetchGeneralNotices() async {
    setState(() => _isGeneralLoading = true);
    try {
      final token = getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/students/general-notices'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _generalNotices =
          List<Map<String, dynamic>>.from(data['notices'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('General notices error: $e');
    } finally {
      setState(() => _isGeneralLoading = false);
    }
  }

  // ─── Fetch unseen counts for all classes ──────────────────────────
  Future<void> _fetchUnseenCounts(List<StudentClassModel> classes) async {
    if (classes.isEmpty) return;
    try {
      final token = getToken();
      final codes = classes.map((c) => c.classCode).join(',');
      final uri =
      Uri.parse('$baseUrl/students/notices-unseen-count')
          .replace(queryParameters: {'classCodes': codes});

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final counts =
        Map<String, dynamic>.from(data['unseenCounts'] ?? {});
        if (mounted) {
          setState(() {
            _unseenCounts =
                counts.map((k, v) => MapEntry(k, (v as num).toInt()));
          });
        }
      }
    } catch (e) {
      debugPrint('Unseen counts error: $e');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.orange;
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy · hh:mm a').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  // Total unseen across all classes for tab badge
  int get _totalUnseenClass =>
      _unseenCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF7),
      body: Column(
        children: [
          Header(
            heading: "Notices",
            subheading: "Notice Hub for students",
          ),

          // ── Tab Bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EDF5)),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF7A8AAA),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  // General Notice tab with badge
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('General Notice'),
                        if (_generalNotices.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_generalNotices.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Class Notice tab with badge
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Class Notice'),
                        if (_totalUnseenClass > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_totalUnseenClass',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Content ─────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: General Notices ────────────────────────
                _buildGeneralNoticesTab(),

                // ── Tab 2: Class Notices ──────────────────────────
                _buildClassNoticesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── General Notices Tab ──────────────────────────────────────────
  Widget _buildGeneralNoticesTab() {
    if (_isGeneralLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildShimmerNotice(),
          _buildShimmerNotice(),
          _buildShimmerNotice(),
        ],
      );
    }

    if (_generalNotices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No general notices',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Admin notices will appear here',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGeneralNotices,
      color: const Color(0xFF00A76F),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _generalNotices.length,
        itemBuilder: (context, index) {
          final notice = _generalNotices[index];
          final priority = notice['priority'] ?? 'normal';
          final color = _getPriorityColor(priority);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: color, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withOpacity(0.25)),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(notice['createdAt'] ?? ''),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notice['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notice['message'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Admin',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Class Notices Tab ────────────────────────────────────────────
  Widget _buildClassNoticesTab() {
    return BlocBuilder<StudentClassBloc, StudentClassState>(
      builder: (context, state) {
        if (state is StudentClassLoading) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
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
                Text(state.message,
                    style:
                    const TextStyle(color: Color(0xFF6B7280))),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchClasses,
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

          // Fetch unseen counts on first load
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchUnseenCounts(state.classes);
          });

          return RefreshIndicator(
            onRefresh: () async {
              await _fetchUnseenCounts(state.classes);
            },
            color: const Color(0xFF00A76F),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.classes.length,
              itemBuilder: (context, index) {
                final cls = state.classes[index];
                final unseen = _unseenCounts[cls.classCode] ?? 0;
                return _buildClassCard(
                  cls,
                  unseen,
                  onReturn: () => _fetchUnseenCounts(state.classes),
                );
              },
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  // ─── Class Card ───────────────────────────────────────────────────
  Widget _buildClassCard(
      StudentClassModel cls,
      int unseenCount, {
        required VoidCallback onReturn,
      }) {
    final Color primary =
    classColors[(cls.classCode.hashCode) % classColors.length];
    final Color secondary =
    classColors[(cls.classCode.hashCode + 1) % classColors.length];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentNoticePage(
              classCode: cls.classCode,
              className: cls.className,
            ),
          ),
        );
        onReturn();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
              top: 0, left: 0, right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      _soften(primary, 0.28),
                      _soften(secondary, 0.28)
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _tint(primary, 0.9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: primary.withOpacity(0.18)),
                        ),
                        child: Icon(Icons.menu_book_outlined,
                            color: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cls.className,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Prof. ${cls.teacherName}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Unseen badge
                      if (unseenCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications,
                                  size: 11, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                '$unseenCount new',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text('${cls.startTime} - ${cls.endTime}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.room_outlined,
                          size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text('Room: ${cls.roomNo}',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
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

  Widget _buildShimmerNotice() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

// ─── Helpers (top-level) ──────────────────────────────────────────────
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
        Text(code,
            style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

Widget _buildShimmerCard() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

const List<Color> classColors = [
  Color(0xFF10B981), Color(0xFF059669),
  Color(0xFF6366F1), Color(0xFF4F46E5),
  Color(0xFF8B5CF6), Color(0xFF7C3AED),
  Color(0xFFF59E0B), Color(0xFFD97706),
  Color(0xFFEF4444), Color(0xFFDC2626),
  Color(0xFF14B8A6), Color(0xFF0D9488),
  Color(0xFF06B6D4), Color(0xFF0891B2),
  Color(0xFFA855F7), Color(0xFF9333EA),
  Color(0xFF3B82F6), Color(0xFF2563EB),
  Color(0xFFF97316), Color(0xFFEA580C),
];

