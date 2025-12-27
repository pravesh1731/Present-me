import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/src/bloc/teacherClass/teacher_class_bloc.dart';
import 'package:present_me_flutter/src/models/class.dart';
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
  int _activeCount = 0;
  late final AnimationController _shimmerController;
  // Track whether we just requested a create/update so we can show a success snackbar
  bool _awaitingSave = false;
  String? _lastAction; // 'create' or 'update'

  // ================= TOKEN =================
  String _getToken() {
    return _storage.read('token')?.toString() ?? '';
  }

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

  // convert 24-hour string 'HH:mm' to 'h:mm AM/PM'
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

  // convert full day name (e.g. "Monday") to short form key (e.g. "Mon")
  String _shortFormFor(String fullDay) {
    if (fullDay.isEmpty) return fullDay;
    try {
      final entry = _dayMap.entries.firstWhere(
        (e) => e.value.toLowerCase() == fullDay.toLowerCase(),
      );
      return entry.key;
    } catch (_) {
      // fallback: return first 3 chars, capitalized first letter
      final s = fullDay.trim();
      if (s.length <= 3) return s;
      return s.substring(0, 3);
    }
  }

  // pick a stripe gradient per class so different classes get different colored stripes
  LinearGradient _stripeGradientFor(ClassModel c) {
    final List<List<Color>> palettes = [
      [const Color(0xFF10B981), const Color(0xFF059669)], // green
      [const Color(0xFF60A5FA), const Color(0xFF2563EB)], // blue
      [const Color(0xFFF97316), const Color(0xFFF43F5E)], // orange->pink
      [const Color(0xFF8B5CF6), const Color(0xFF6366F1)], // purple
      [const Color(0xFFF59E0B), const Color(0xFFF97316)], // amber
      [const Color(0xFF34D399), const Color(0xFF10B981)], // teal
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
    // initialize _activeCount from current bloc state in case data was already loaded
    try {
      final bloc = context.read<TeacherClassBloc>();
      final st = bloc.state;
      if (st is TeacherClassLoaded) {
        _activeCount = st.classes.length;
      }
    } catch (_) {
      // ignore if bloc not available yet
    }
    if (token.isNotEmpty) {
      context.read<TeacherClassBloc>().add(TeacherFetchClasses(token));
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // Small shader-based shimmer helper
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

  // A simple gray placeholder that mirrors the class card structure
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
                            Container(
                              height: 16,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                            ),
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
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 90,
                        color: Colors.grey.shade300,
                      ),
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
        // listen to bloc state changes so we can update the active class count shown in the header
        child: BlocListener<TeacherClassBloc, TeacherClassState>(
          listener: (context, state) {
            if (state is TeacherClassLoaded) {
              // update active count to number of loaded classes
              setState(() {
                _activeCount = state.classes.length;
              });

              // If we were awaiting a save (create/update), show a toast (Fluttertoast)
              if (_awaitingSave && _lastAction != null) {
                final successMessage = _lastAction == 'create' ? 'Class created successfully' : 'Class updated successfully';
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
            } else if (state is TeacherClassLoading) {
              setState(() {
                _activeCount = 0;
              });
            } else if (state is TeacherClassError) {
              // update minimal UI state
              setState(() {
                _activeCount = 0;
              });

              // Show the actual error message in a snackbar
              final errMsg = state.message;
              Fluttertoast.showToast(
                msg: errMsg,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.TOP,
                backgroundColor: Colors.redAccent,
                textColor: Colors.white,
                fontSize: 14,
              );


              // // If an error occurred while awaiting save, show a contextual error snackbar as well
              // if (_awaitingSave && _lastAction != null) {
              //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to ${_lastAction == 'create' ? 'create' : 'update'} class')));
              //   _awaitingSave = false;
              //   _lastAction = null;
              // }

              // Attempt a single automatic retry to reload the classes (if token present)
              final token = _getToken();
              if (token.isNotEmpty) {
                // schedule a microtask to avoid calling bloc while in the middle of processing the current event
                Future.microtask(() => context.read<TeacherClassBloc>().add(TeacherFetchClasses(token)));
              }
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildModernHeader()),

              SliverToBoxAdapter(child: _buildModernTabs(_activeCount)),

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

                  if (state is TeacherClassLoaded && state.classes.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No Classes')),
                    );
                  }

                  if (state is TeacherClassLoaded) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildModernClassCard(state.classes[i]),
                        childCount: state.classes.length,
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
  Widget _buildModernHeader() {
    // 'My Classes' header that matches the provided screenshot
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)], // green gradient
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total classes $_activeCount',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TABS =================
  Widget _buildModernTabs(int active) {
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
                    color:
                        _selectedTab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Active ($active)',
                    style: TextStyle(
                      color:
                          _selectedTab == 0
                              ? const Color(0xFF2563EB)
                              : Colors.black54,
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
                    color:
                        _selectedTab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Inactive (0)', // Inactive tab always shows 0
                    style: TextStyle(
                      color:
                          _selectedTab == 1
                              ? const Color(0xFF2563EB)
                              : Colors.black54,
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
    final students = c.students.length;
    final int attendance = 94; // show a realistic value like your screenshot
    final badgeColor =
        attendance >= 90
            ? Colors.green
            : (attendance >= 75 ? Colors.orange : Colors.red);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // top colored stripe with rounded ends matching the outer card's top corner radius
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
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: icon, class name and edit icon
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
                          child: Icon(
                            Icons.menu_book,
                            color: Color(0xFF059669),
                            size: 25,
                          ),
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
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                              
                                    ),
                              
                              
                                  SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      c.classDays
                                          .map((d) => _shortFormFor(d))
                                          .join(', '),
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

                            // three-dots menu styled like the provided screenshot (Edit / Move to Inactive / Delete)
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.more_vert,
                                size: 22,
                                color: Colors.black54,
                              ),
                              color: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  _showEditDialog(c);
                                  return;
                                }

                                if (v == 'move') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text('Move to Inactive'),
                                          content: const Text(
                                            'Are you sure you want to move this class to inactive?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('Move'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (confirm == true) {
                                    // For now show a snackbar. Hook up real move logic in bloc if available.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Class moved to inactive',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                if (v == 'delete') {
                                  final confirm = await _showDeleteConfirmation(
                                    c,
                                  );
                                  if (confirm == true) {
                                    final token = _getToken();
                                    if (token.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Not authenticated'),
                                        ),
                                      );
                                      return;
                                    }
                                    context.read<TeacherClassBloc>().add(
                                      TeacherDeleteClass(
                                        token: token,
                                        classCode: c.classCode,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Deleting class...'),
                                      ),
                                    );
                                  }
                                  return;
                                }
                              },
                              itemBuilder:
                                  (ctx) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: Colors.black54,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Edit Class'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'move',
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.swap_horiz,
                                            size: 20,
                                            color: Colors.black54,
                                          ),
                                          SizedBox(width: 12),
                                          Text('Move to Inactive'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: const [
                                          Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Delete Class',
                                            style: TextStyle(color: Colors.red),
                                          ),
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
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatTo12(c.startTime)} - ${_formatTo12(c.endTime)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Room ${c.roomNo}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$students students',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor, // solid green background
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '$attendance% attendance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // full width Start Class gradient button
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
                  icon: const Icon(
                    Icons.remove_red_eye,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'View Class',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                classDetailsStudentList(classCode: c.classCode),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CREATE =================
  void _showCreateDialog() {
    _showClassDialog();
  }

  // ================= EDIT =================
  void _showEditDialog(ClassModel c) {
    _showClassDialog(existing: c);
  }

  // ================= COMMON DIALOG =================
  void _showClassDialog({ClassModel? existing}) {
    final nameController = TextEditingController(
      text: existing?.className ?? '',
    );
    final roomController = TextEditingController(text: existing?.roomNo ?? '');
    TimeOfDay? start = existing == null ? null : _parseTime(existing.startTime);
    TimeOfDay? end = existing == null ? null : _parseTime(existing.endTime);
    final selectedDays = <String>{
      ...existing?.classDays.map(
            (d) =>
                _dayMap.entries
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
      builder:
          (_) => _ClassDialog(
            nameController: nameController,
            roomController: roomController,
            start: start,
            end: end,
            selectedDays: selectedDays,
            dayMap: _dayMap,
            onSave: (
              String name,
              String room,
              TimeOfDay? s,
              TimeOfDay? e,
              Set<String> days,
            ) {
              final token = _getToken();
              if (token.isEmpty) return;
              if (existing == null) {
                setState(() {
                  _awaitingSave = true;
                  _lastAction = 'create';
                });
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
                setState(() {
                  _awaitingSave = true;
                  _lastAction = 'update';
                });
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

  // reusable styled delete confirmation dialog (reworked to match the provided UI)
  Future<bool?> _showDeleteConfirmation(ClassModel c) {
    final className = c.className;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient and icon + close button
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
                      // Center content (icon + title + subtitle)
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // circular icon backdrop
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(255, 255, 255, 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Delete Class?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'This action cannot be undone',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // floating close button (slightly overlapping top-right corner)
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
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.12),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Warning box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5), // very light red
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Color(0xFFEF4444),
                              ),
                            ),

                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Warning',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB91C1C),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        height: 1.35,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Deleting "',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        TextSpan(
                                          text: className,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              '" will permanently remove.\n\n',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              '• All class attendance records\n',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '• Student enrollment data\n',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '• Class notes and materials\n',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        const TextSpan(
                                          text: '• Grade and score history',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
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

                      // Buttons row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(ctx, true),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Delete Class',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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

class _ClassDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController roomController;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final Set<String> selectedDays;
  final Map<String, String> dayMap;
  final void Function(String, String, TimeOfDay?, TimeOfDay?, Set<String>)
  onSave;
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

  // validation errors
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
            // header
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(255, 255, 255, 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.nameController.text.isEmpty
                                      ? 'Create New Class'
                                      : 'Edit Class',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Set up your class details',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // body
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Class name
                  TextField(
                    controller: widget.nameController,
                    decoration: InputDecoration(
                      labelText: 'Class Name',
                      hintText: 'e.g., Grade 10 - Mathematics',
                      errorText: _nameError,
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      prefixIcon: const Icon(
                        Icons.menu_book,
                        color: Color(0xFF06B6D4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Room number (single field as per your request)
                  TextField(
                    controller: widget.roomController,
                    decoration: InputDecoration(
                      labelText: 'Room Number',
                      hintText: 'e.g., 301',
                      errorText: _roomError,
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color(0xFF06B6D4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      if (_roomError != null) setState(() => _roomError = null);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Times row (Start / End)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.black54,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  start == null
                                      ? '--:-- --'
                                      : '${start!.hourOfPeriod == 0 ? 12 : start!.hourOfPeriod}:${start!.minute.toString().padLeft(2, '0')} ${start!.period.name.toUpperCase()}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: start ?? TimeOfDay.now(),
                                  );
                                  if (picked != null)
                                    setState(() => start = picked);
                                },
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.black54,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  end == null
                                      ? '--:-- --'
                                      : '${end!.hourOfPeriod == 0 ? 12 : end!.hourOfPeriod}:${end!.minute.toString().padLeft(2, '0')} ${end!.period.name.toUpperCase()}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: end ?? TimeOfDay.now(),
                                  );
                                  if (picked != null)
                                    setState(() => end = picked);
                                },
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_timeError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _timeError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Class days
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children:
                        widget.dayMap.keys
                            .map(
                              (d) => ChoiceChip(
                                label: Text(d),
                                selected: selectedDays.contains(d),
                                onSelected:
                                    (v) => setState(() {
                                      v
                                          ? selectedDays.add(d)
                                          : selectedDays.remove(d);
                                      if (_daysError != null &&
                                          selectedDays.isNotEmpty)
                                        _daysError = null;
                                    }),
                                backgroundColor: const Color(0xFFF3F4F6),
                                selectedColor: const Color(
                                  0xFF06B6D4,
                                ).withOpacity(0.5),
                                labelStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  if (_daysError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _daysError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // validate
                            setState(() {
                              _nameError =
                                  (widget.nameController.text.trim().isEmpty)
                                      ? 'Please enter class name'
                                      : null;
                              _roomError =
                                  (widget.roomController.text.trim().isEmpty)
                                      ? 'Please enter room number'
                                      : null;
                              if (start == null || end == null) {
                                _timeError = 'Please select start and end time';
                              } else if (_minutes(start!) >= _minutes(end!)) {
                                _timeError =
                                    'Start time must be before end time';
                              } else {
                                _timeError = null;
                              }
                              _daysError =
                                  (selectedDays.isEmpty)
                                      ? 'Please select at least one day'
                                      : null;
                            });

                            final hasError =
                                _nameError != null ||
                                _roomError != null ||
                                _timeError != null ||
                                _daysError != null;
                            if (!hasError) {
                              widget.onSave(
                                widget.nameController.text.trim(),
                                widget.roomController.text.trim(),
                                start,
                                end,
                                selectedDays,
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF06B6D9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            widget.nameController.text.isEmpty
                                ? 'Create'
                                : 'Update',
                            style: TextStyle(color: Colors.black),
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

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;
}
