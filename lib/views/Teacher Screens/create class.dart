import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import '../../models/class.dart';
import '../../viewmodels/teacher_class/teacher_class_bloc.dart';
import 'classDetailsStudentList.dart';

class CreateClass extends StatefulWidget {
  const CreateClass({super.key});

  @override
  State<CreateClass> createState() => _CreateClassState();
}

class _CreateClassState extends State<CreateClass>
    with SingleTickerProviderStateMixin {
  final GetStorage _storage = GetStorage();
  int _selectedTab = 0;
  late final AnimationController _shimmerController;
  bool _awaitingSave = false;
  String? _lastAction;

  // ================= TOKEN =================
  String _getToken() => _storage.read('token')?.toString() ?? '';

  // ================= TIME FORMAT =================
  String _formatTime24(TimeOfDay? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay? _parseTime(String s) {
    if (s.isEmpty) return null;
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTo12(String s) {
    if (s.isEmpty) return '';
    try {
      final parts = s.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      final period = h >= 12 ? 'PM' : 'AM';
      final hour12 = (h % 12 == 0) ? 12 : h % 12;
      return '$hour12:${m.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return s;
    }
  }

  // ================= DAY MAP =================
  static const Map<String, String> _dayMap = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
  };

  String _shortFormFor(String fullDay) {
    if (fullDay.isEmpty) return fullDay;
    try {
      final entry = _dayMap.entries.firstWhere(
            (e) => e.value.toLowerCase() == fullDay.toLowerCase(),
      );
      return entry.key;
    } catch (_) {
      final s = fullDay.trim();
      if (s.length <= 3) return s;
      return s.substring(0, 3);
    }
  }

  LinearGradient _stripeGradientFor(ClassModel c) {
    final List<List<Color>> palettes = [
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFF60A5FA), const Color(0xFF2563EB)],
      [const Color(0xFFF97316), const Color(0xFFF43F5E)],
      [const Color(0xFF8B5CF6), const Color(0xFF6366F1)],
      [const Color(0xFFF59E0B), const Color(0xFFF97316)],
      [const Color(0xFF34D399), const Color(0xFF10B981)],
    ];
    final keySource = (c.classCode.isNotEmpty ? c.classCode : c.className);
    final idx = keySource.hashCode.abs() % palettes.length;
    final cols = palettes[idx];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: cols,
    );
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    final token = _getToken();
    if (token.isNotEmpty) {
      context.read<TeacherClassBloc>().add(TeacherFetchClasses(token));
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // ================= SHIMMER =================
  Widget _shimmer(Widget child) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            final shimmerWidth = rect.width * 0.6;
            final offset =
                (_shimmerController.value * (rect.width + shimmerWidth)) -
                    shimmerWidth;
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1 - (offset / rect.width), 0),
              end: Alignment(1 - (offset / rect.width), 0),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 16, width: double.infinity, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Container(
                              height: 20,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(height: 12, width: 120, color: Colors.grey.shade300),
                      const SizedBox(width: 12),
                      Container(height: 12, width: 80, color: Colors.grey.shade300),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(height: 12, width: 90, color: Colors.grey.shade300),
                      const SizedBox(width: 12),
                      Container(
                        height: 28,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocListener<TeacherClassBloc, TeacherClassState>(
          listener: (context, state) {
            if (state is TeacherClassLoaded) {
              if (_awaitingSave && _lastAction != null) {
                final successMessage = _lastAction == 'create'
                    ? 'Class created successfully'
                    : _lastAction == 'update'
                    ? 'Class updated successfully'
                    : 'Class status updated';
                Fluttertoast.showToast(
                  msg: successMessage,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: const Color(0xFF10B981),
                  textColor: Colors.white,
                  fontSize: 14,
                );
                _awaitingSave = false;
                _lastAction = null;
              }
            } else if (state is TeacherClassError) {
              Fluttertoast.showToast(
                msg: state.message,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.redAccent,
                textColor: Colors.white,
                fontSize: 14,
              );
              final token = _getToken();
              if (token.isNotEmpty) {
                Future.microtask(
                      () => context.read<TeacherClassBloc>().add(TeacherFetchClasses(token)),
                );
              }
            }
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: BlocBuilder<TeacherClassBloc, TeacherClassState>(
                  builder: (context, state) {
                    final activeCount = state is TeacherClassLoaded
                        ? state.classes.where((c) => c.isActive).length
                        : 0;
                    return _buildModernHeader(activeCount);
                  },
                ),
              ),

              // ── Tabs ──
              SliverToBoxAdapter(
                child: BlocBuilder<TeacherClassBloc, TeacherClassState>(
                  builder: (context, state) {
                    final active = state is TeacherClassLoaded
                        ? state.classes.where((c) => c.isActive).length
                        : 0;
                    final inactive = state is TeacherClassLoaded
                        ? state.classes.where((c) => !c.isActive).length
                        : 0;
                    return _buildModernTabs(active, inactive);
                  },
                ),
              ),

              // ── List ──
              BlocBuilder<TeacherClassBloc, TeacherClassState>(
                builder: (context, state) {
                  if (state is TeacherClassLoading) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, __) => _shimmer(_buildShimmerCard()),
                        childCount: 3,
                      ),
                    );
                  }

                  if (state is TeacherClassLoaded) {
                    // ✅ Filter by selected tab
                    final displayed = _selectedTab == 0
                        ? state.classes.where((c) => c.isActive).toList()
                        : state.classes.where((c) => !c.isActive).toList();

                    if (displayed.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedTab == 0
                                    ? Icons.class_outlined
                                    : Icons.archive_outlined,
                                size: 56,
                                color: Colors.black12,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 0
                                    ? 'No Active Classes\nTap + to create one'
                                    : 'No Inactive Classes',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black38, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (_, i) => _buildModernClassCard(displayed[i]),
                        childCount: displayed.length,
                      ),
                    );
                  }

                  if (state is TeacherClassError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(state.message)),
                    );
                  }

                  return const SliverFillRemaining(child: SizedBox());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildModernHeader(int activeCount) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Classes',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Total active classes $activeCount',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TABS =================
  Widget _buildModernTabs(int active, int inactive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Active ($active)',
                    style: TextStyle(
                      color: _selectedTab == 0 ? const Color(0xFF2563EB) : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Inactive ($inactive)',
                    style: TextStyle(
                      color: _selectedTab == 1 ? const Color(0xFF2563EB) : Colors.black54,
                      fontWeight: FontWeight.bold,
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

  // ================= CARD =================
  Widget _buildModernClassCard(ClassModel c) {
    // ✅ Use real averageAttendance from model
    final double attendance = c.averageAttendance;
    final Color badgeColor = attendance >= 90
        ? Colors.green
        : (attendance >= 75 ? Colors.orange : Colors.red);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          // ✅ Slightly dimmed for inactive classes
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(c.isActive ? 10 : 5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: c.isActive ? 1.0 : 0.6,  // ✅ dim inactive cards
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // top stripe
              Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: _stripeGradientFor(c),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6FDF3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.menu_book, color: Color(0xFF059669), size: 25),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.className,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        c.classDays.map((d) => _shortFormFor(d)).join(', '),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // three-dots menu
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 22, color: Colors.black54),
                                color: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    _showEditDialog(c);
                                    return;
                                  }

                                  if (v == 'move') {
                                    // ✅ Toggle active/inactive
                                    final isCurrentlyActive = c.isActive;
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(isCurrentlyActive ? 'Move to Inactive' : 'Reactivate Class'),
                                        content: Text(
                                          isCurrentlyActive
                                              ? 'Are you sure you want to move this class to inactive?'
                                              : 'Are you sure you want to reactivate this class?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text(isCurrentlyActive ? 'Move' : 'Activate'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final token = _getToken();
                                      if (token.isEmpty) return;
                                      setState(() {
                                        _awaitingSave = true;
                                        _lastAction = 'toggle';
                                      });
                                      // ✅ Dispatch toggle event
                                      context.read<TeacherClassBloc>().add(
                                        TeacherToggleClassStatus(
                                          token: token,
                                          classCode: c.classCode,
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  if (v == 'delete') {
                                    final confirm = await _showDeleteConfirmation(c);
                                    if (confirm == true) {
                                      final token = _getToken();
                                      if (token.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Not authenticated')),
                                        );
                                        return;
                                      }
                                      context.read<TeacherClassBloc>().add(
                                        TeacherDeleteClass(token: token, classCode: c.classCode),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Deleting class...')),
                                      );
                                    }
                                    return;
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.edit, size: 20, color: Colors.black54),
                                        SizedBox(width: 12),
                                        Text('Edit Class'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'move',
                                    child: Row(
                                      children: [
                                        Icon(
                                          c.isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                                          size: 20,
                                          color: Colors.black54,
                                        ),
                                        const SizedBox(width: 12),
                                        // ✅ Label changes based on current status
                                        Text(c.isActive ? 'Move to Inactive' : 'Move to Active'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Delete Class', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.black38),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatTo12(c.startTime)} - ${_formatTo12(c.endTime)}',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Room ${c.roomNo}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 16, color: Colors.black38),
                            const SizedBox(width: 6),
                            Text(
                              // ✅ use totalStudents from model
                              '${c.totalStudents} Stud.',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.vpn_key_outlined, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Text(c.classCode),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              // ✅ real average attendance
                              '${c.averageAttendance.toStringAsFixed(1)}% Avg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // View Class button — hidden for inactive
              if (c.isActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton.icon(
                      icon: const Icon(Icons.remove_red_eye, size: 18, color: Colors.white),
                      label: const Text('View Class', style: TextStyle(fontSize: 16, color: Colors.white)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => classDetailsStudentList(
                              classCode: c.classCode,
                              roomNo: c.roomNo,
                              className1: c.className,
                              classDays: c.classDays,
                              startTime: c.startTime,
                              endTime: c.endTime,
                              totalStudents: c.totalStudents,
                              totalClasses: c.totalClasses,
                              averageAttendance: c.averageAttendance,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

              // ✅ Reactivate button for inactive cards
              if (!c.isActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.unarchive_outlined, size: 18),
                    label: const Text('Reactivate Class'),
                    onPressed: () {
                      final token = _getToken();
                      if (token.isEmpty) return;
                      setState(() {
                        _awaitingSave = true;
                        _lastAction = 'toggle';
                      });
                      context.read<TeacherClassBloc>().add(
                        TeacherToggleClassStatus(token: token, classCode: c.classCode),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      foregroundColor: const Color(0xFF2563EB),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CREATE =================
  void _showCreateDialog() => _showClassDialog();

  // ================= EDIT =================
  void _showEditDialog(ClassModel c) => _showClassDialog(existing: c);

  // ================= COMMON DIALOG =================
  void _showClassDialog({ClassModel? existing}) {
    final nameController = TextEditingController(text: existing?.className ?? '');
    final roomController = TextEditingController(text: existing?.roomNo ?? '');
    TimeOfDay? start = existing == null ? null : _parseTime(existing.startTime);
    TimeOfDay? end = existing == null ? null : _parseTime(existing.endTime);
    final selectedDays = <String>{
      ...existing?.classDays.map(
            (d) => _dayMap.entries
            .firstWhere(
              (e) => e.value == d,
          orElse: () => const MapEntry('Mon', 'Monday'),
        )
            .key,
      ) ??
          {},
    };
    showDialog(
      context: context,
      builder: (_) => _ClassDialog(
        nameController: nameController,
        roomController: roomController,
        start: start,
        end: end,
        selectedDays: selectedDays,
        dayMap: _dayMap,
        onSave: (String name, String room, TimeOfDay? s, TimeOfDay? e, Set<String> days) {
          final token = _getToken();
          if (token.isEmpty) return;
          if (existing == null) {
            setState(() { _awaitingSave = true; _lastAction = 'create'; });
            context.read<TeacherClassBloc>().add(
              TeacherCreateClass(
                token: token,
                className: name.trim(),
                roomNo: room.trim(),
                startTime: _formatTime24(s),
                endTime: _formatTime24(e),
                classDays: days.map((d) => _dayMap[d]!).toList(),
              ),
            );
          } else {
            setState(() { _awaitingSave = true; _lastAction = 'update'; });
            context.read<TeacherClassBloc>().add(
              TeacherUpdateClass(
                token: token,
                classCode: existing.classCode,
                className: name.trim(),
                roomNo: room.trim(),
                startTime: _formatTime24(s),
                endTime: _formatTime24(e),
                classDays: days.map((d) => _dayMap[d]!).toList(),
              ),
            );
          }
        },
      ),
    );
  }

  // ================= DELETE DIALOG =================
  Future<bool?> _showDeleteConfirmation(ClassModel c) {
    final className = c.className;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 170,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFB7185), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(255, 255, 255, 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Center(
                                child: Icon(Icons.auto_awesome, color: Colors.white, size: 34),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Delete Class?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'This action cannot be undone',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 14,
                        top: 14,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(255, 255, 255, 0.18),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.12), blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Center(child: Icon(Icons.close, color: Colors.white, size: 18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(child: Icon(Icons.error_outline, color: Color(0xFFEF4444))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Warning',
                                    style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB91C1C), fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black87, height: 1.35),
                                      children: [
                                        TextSpan(text: 'Deleting "', style: const TextStyle(color: Color(0xFFEF4444))),
                                        TextSpan(text: className, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                                        const TextSpan(text: '" will permanently remove.\n\n', style: TextStyle(color: Color(0xFFEF4444))),
                                        const TextSpan(text: '• All class attendance records\n', style: TextStyle(color: Color(0xFFEF4444))),
                                        const TextSpan(text: '• Student enrollment data\n', style: TextStyle(color: Color(0xFFEF4444))),
                                        const TextSpan(text: '• Class notes and materials\n', style: TextStyle(color: Color(0xFFEF4444))),
                                        const TextSpan(text: '• Grade and score history', style: TextStyle(color: Color(0xFFEF4444))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(ctx, true),
                              icon: const Icon(Icons.delete_outline, color: Colors.white),
                              label: const Text('Delete Class', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.red.shade600,
                                elevation: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Consider inactivate instead of deleting to preserve records',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= CLASS DIALOG =================
class _ClassDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController roomController;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final Set<String> selectedDays;
  final Map<String, String> dayMap;
  final void Function(String, String, TimeOfDay?, TimeOfDay?, Set<String>) onSave;

  const _ClassDialog({
    required this.nameController,
    required this.roomController,
    required this.start,
    required this.end,
    required this.selectedDays,
    required this.dayMap,
    required this.onSave,
  });

  @override
  State<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends State<_ClassDialog> {
  late TimeOfDay? start = widget.start;
  late TimeOfDay? end = widget.end;
  late Set<String> selectedDays = Set<String>.from(widget.selectedDays);

  String? _nameError;
  String? _roomError;
  String? _timeError;
  String? _daysError;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: Color.fromRGBO(255, 255, 255, 0.12), shape: BoxShape.circle),
                        child: const Center(child: Icon(Icons.auto_awesome, color: Colors.white, size: 26)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nameController.text.isEmpty ? 'Create New Class' : 'Edit Class',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            const Text('Set up your class details', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: widget.nameController,
                    decoration: InputDecoration(
                      labelText: 'Class Name',
                      hintText: 'e.g., Grade 10 - Mathematics',
                      errorText: _nameError,
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      prefixIcon: const Icon(Icons.menu_book, color: Color(0xFF06B6D4)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: widget.roomController,
                    decoration: InputDecoration(
                      labelText: 'Room Number',
                      hintText: 'e.g., 301',
                      errorText: _roomError,
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      prefixIcon: const Icon(Icons.location_on, color: Color(0xFF06B6D4)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) { if (_roomError != null) setState(() => _roomError = null); },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _timePicker('Start', start, (t) => setState(() => start = t))),
                      const SizedBox(width: 10),
                      Expanded(child: _timePicker('End', end, (t) => setState(() => end = t))),
                    ],
                  ),
                  if (_timeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_timeError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: widget.dayMap.keys.map((d) => ChoiceChip(
                      label: Text(d),
                      selected: selectedDays.contains(d),
                      onSelected: (v) => setState(() {
                        v ? selectedDays.add(d) : selectedDays.remove(d);
                        if (_daysError != null && selectedDays.isNotEmpty) _daysError = null;
                      }),
                      backgroundColor: const Color(0xFFF3F4F6),
                      selectedColor: const Color(0xFF06B6D4).withOpacity(0.5),
                      labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    )).toList(),
                  ),
                  if (_daysError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_daysError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _nameError = widget.nameController.text.trim().isEmpty ? 'Please enter class name' : null;
                              _roomError = widget.roomController.text.trim().isEmpty ? 'Please enter room number' : null;
                              if (start == null || end == null) {
                                _timeError = 'Please select start and end time';
                              } else if (_minutes(start!) >= _minutes(end!)) {
                                _timeError = 'Start time must be before end time';
                              } else {
                                _timeError = null;
                              }
                              _daysError = selectedDays.isEmpty ? 'Please select at least one day' : null;
                            });
                            final hasError = _nameError != null || _roomError != null || _timeError != null || _daysError != null;
                            if (!hasError) {
                              widget.onSave(widget.nameController.text.trim(), widget.roomController.text.trim(), start, end, selectedDays);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF06B6D9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            widget.nameController.text.isEmpty ? 'Create' : 'Update',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePicker(String label, TimeOfDay? time, void Function(TimeOfDay) onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time ?? TimeOfDay.now());
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.black54, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                time == null
                    ? '$label --:-- --'
                    : '$label ${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period.name.toUpperCase()}',
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;
}