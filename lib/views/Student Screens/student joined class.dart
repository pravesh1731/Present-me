import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/views/Student%20Screens/student%20attendance%20Details.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/studentClass.dart';
import '../../repositories/studentClass_repository.dart';
import '../../viewmodels/student_class/student_class_bloc.dart';
import 'StudentJoinedClassScreen.dart';

class joined_Class extends StatefulWidget {
  @override
  State<joined_Class> createState() => _joined_ClassState();
}

class _joined_ClassState extends State<joined_Class> {
  final GetStorage _storage = GetStorage();
  final TextEditingController _codeController = TextEditingController();
  int _selectedTab = 0;
  List<StudentClassModel> _cachedClasses = [];

  // ✅ Track whether join dialog is open so we can control it
  bool _isJoinDialogOpen = false;

  String _getToken() => _storage.read('token')?.toString() ?? '';

  static const Map<String, String> _dayMap = {
    'Mon': 'Monday', 'Tue': 'Tuesday', 'Wed': 'Wednesday',
    'Thu': 'Thursday', 'Fri': 'Friday', 'Sat': 'Saturday', 'Sun': 'Sunday',
  };

  String _shortFormFor(String fullDay) {
    if (fullDay.isEmpty) return fullDay;
    try {
      return _dayMap.entries.firstWhere(
            (e) => e.value.toLowerCase() == fullDay.toLowerCase(),
      ).key;
    } catch (_) {
      final s = fullDay.trim();
      return s.length <= 3 ? s : s.substring(0, 3);
    }
  }

  static const List<Color> _classColors = [
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final token = _getToken();
        if (token.isNotEmpty) {
          context.read<StudentClassBloc>().add(StudentFetchEnrolledClasses(token));
        }
      } catch (e) {}
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ✅ FIXED: Dialog with StatefulBuilder for inline validation + stays open on error
  void _showJoinClassDialog() {
    _codeController.clear();
    String? _inlineError; // local error shown inside dialog
    bool _isLoading = false;

    _isJoinDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return BlocListener<StudentClassBloc, StudentClassState>(
            listener: (ctx, state) {
              if (state is StudentClassActionSuccess) {
                // ✅ Close dialog on success
                if (_isJoinDialogOpen) {
                  _isJoinDialogOpen = false;
                  Navigator.of(dialogContext).pop();
                }
                // ✅ Show success snackbar
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ));
                // ✅ Refresh class list after join
                final token = _getToken();
                if (token.isNotEmpty) {
                  context.read<StudentClassBloc>().add(StudentFetchEnrolledClasses(token));
                }
              }

              if (state is StudentClassJoinError) {
                setDialogState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                ));
              }
            },
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
              elevation: 24,
              child: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 420),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
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
                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 4))],
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
                                Text('Join Class', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                                SizedBox(height: 4),
                                Text('Enter the class code to join', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                _isJoinDialogOpen = false;
                                _codeController.clear();
                                Navigator.pop(dialogContext);
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

                    // ── Body ──
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
                                  const Text('6-Digit Class Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // ✅ TextField with inline error border
                              TextField(
                                controller: _codeController,
                                maxLength: 6,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 2),
                                onChanged: (_) {
                                  if (_inlineError != null) {
                                    setDialogState(() => _inlineError = null);
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter 6-digit code',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  filled: true,
                                  fillColor: Colors.white,
                                  counterText: '',
                                  // ✅ Show red border when there's an inline error
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: _inlineError != null ? Colors.red : Colors.grey.shade200, width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: _inlineError != null ? Colors.red.shade300 : Colors.grey.shade200, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: _inlineError != null ? Colors.red : const Color(0xFF2563EB),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  // ✅ Inline error message below field
                                  errorText: _inlineError,
                                  errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ✅ Join Button — shows loader while joining
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isLoading
                                        ? [Colors.grey.shade400, Colors.grey.shade500]
                                        : [const Color(0xFF06B6D4), const Color(0xFF2563EB)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isLoading ? Colors.grey : const Color(0xFF2563EB)).withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _isLoading
                                        ? null
                                        : () {
                                      final code = _codeController.text.trim();

                                      // ✅ FIX 1: Empty code validation
                                      if (code.isEmpty) {
                                        setDialogState(() => _inlineError = 'Please enter a class code');
                                        return;
                                      }

                                      // ✅ FIX 2: Less than 6 digits validation
                                      if (code.length < 6) {
                                        setDialogState(() => _inlineError = 'Code must be exactly 6 digits');
                                        return;
                                      }

                                      final token = _getToken();
                                      if (token.isEmpty) return;

                                      setDialogState(() {
                                        _inlineError = null;
                                        _isLoading = true;
                                      });

                                      context.read<StudentClassBloc>().add(
                                        StudentJoinClass(token: token, classCode: code),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: _isLoading
                                          ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Joining...', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                                        ],
                                      )
                                          : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.login_rounded, color: Colors.white, size: 22),
                                          SizedBox(width: 10),
                                          Text('Join Class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
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
        },
      ),
    ).then((_) {
      _isJoinDialogOpen = false;
    });
  }

  Widget _buildList(List<StudentClassModel> allClasses) {
    final activeClasses   = allClasses.where((c) => c.isActive).toList();
    final inactiveClasses = allClasses.where((c) => !c.isActive).toList();
    final displayed = _selectedTab == 0 ? activeClasses : inactiveClasses;

    if (displayed.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildHeader(activeClasses.length, inactiveClasses.length),
          _buildTabs(activeClasses.length, inactiveClasses.length),
          const SizedBox(height: 24),
          _buildEmptyState(),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: displayed.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(activeClasses.length, inactiveClasses.length);
        if (index == 1) return _buildTabs(activeClasses.length, inactiveClasses.length);
        return _buildClassCard(displayed[index - 2]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinClassDialog,
        backgroundColor: const Color(0xFF2563EB),
        tooltip: 'Join Class',
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
          child: BlocBuilder<StudentClassBloc, StudentClassState>(
            // ✅ Rebuild only on relevant states (not action success/error mid-join)
            buildWhen: (prev, curr) =>
                curr is StudentClassLoaded ||
                curr is StudentClassLoading ||
                curr is StudentClassInitial,
            builder: (context, state) {
              if (state is StudentClassLoaded) {
                _cachedClasses = List<StudentClassModel>.from(state.classes);
                if (state.classes.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _buildHeader(0, 0),
                      _buildTabs(0, 0),
                      const SizedBox(height: 24),
                      _buildEmptyState(),
                    ],
                  );
                }
                return _buildList(state.classes);
              }

              if (state is StudentClassLoading) {
                if (_cachedClasses.isNotEmpty) return _buildList(_cachedClasses);
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildHeader(0, 0),
                    _buildTabs(0, 0),
                    const SizedBox(height: 8),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                  ],
                );
              }

              if (state is StudentClassError) {
                if (_cachedClasses.isNotEmpty) return _buildList(_cachedClasses);
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildHeader(0, 0),
                    _buildTabs(0, 0),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.message, style: const TextStyle(color: Color(0xFF6B7280))),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              final token = _getToken();
                              if (token.isNotEmpty) {
                                context.read<StudentClassBloc>().add(StudentFetchEnrolledClasses(token));
                              }
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (_cachedClasses.isNotEmpty) return _buildList(_cachedClasses);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    Widget content;
    try {
      BlocProvider.of<StudentClassBloc>(context);
      content = scaffold;
    } catch (_) {
      content = BlocProvider(
        create: (ctx) {
          final bloc = StudentClassBloc(repository: StudentClassRepository());
          final token = _getToken();
          if (token.isNotEmpty) bloc.add(StudentFetchEnrolledClasses(token));
          return bloc;
        },
        child: scaffold,
      );
    }

    return content;
  }

  // ================= HEADER =================
  Widget _buildHeader(int activeCount, int inactiveCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      padding: const EdgeInsets.fromLTRB(20, 44, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Classes', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '$activeCount active · $inactiveCount inactive',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
              child: IconButton(
                color: Colors.white,
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentJoinedClassScreen())),
                icon: const Icon(Icons.access_time),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TABS =================
  Widget _buildTabs(int activeCount, int inactiveCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            _tabItem(label: 'Active ($activeCount)', index: 0),
            _tabItem(label: 'Inactive ($inactiveCount)', index: 1),
          ],
        ),
      ),
    );
  }

  Widget _tabItem({required String label, required int index}) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF2563EB) : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ================= EMPTY STATE =================
  Widget _buildEmptyState() {
    final isActiveTab = _selectedTab == 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF06B6D4).withOpacity(0.1), const Color(0xFF2563EB).withOpacity(0.1)]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActiveTab ? Icons.school_outlined : Icons.archive_outlined,
              size: 80,
              color: const Color(0xFF06B6D4).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isActiveTab ? 'No Active Classes' : 'No Inactive Classes',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            isActiveTab
                ? "You haven't joined any active classes yet.\nTap the + button to join a class."
                : "No inactive classes found.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  // ================= CLASS CARD =================
  Widget _buildClassCard(StudentClassModel cls) {
    final Color primary   = _classColors[(cls.classCode.hashCode) % _classColors.length];
    final Color secondary = _classColors[(cls.classCode.hashCode + 1) % _classColors.length];

    return Opacity(
      opacity: cls.isActive ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: () {
          if (!cls.isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('This class is currently inactive'),
                  ],
                ),
                backgroundColor: Colors.grey.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentAttendanceDetails(
                classCode: cls.classCode,
                teacherName: cls.teacherName,
                className: cls.className,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
                          width: 42, height: 42,
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
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cls.className,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text("(Prof. ${cls.teacherName})", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6, runSpacing: 6,
                                children: cls.classDays.isNotEmpty
                                    ? cls.classDays.map((d) => _buildBadge(_shortFormFor(d))).toList()
                                    : [_buildBadge('No days')],
                              ),
                            ],
                          ),
                        ),
                        if (!cls.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(999)),
                            child: const Text('Inactive', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.black45),
                        const SizedBox(width: 6),
                        Text('${cls.startTime} -', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(cls.endTime, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.room_outlined, size: 16, color: Colors.black45),
                        const SizedBox(width: 6),
                        Text('Room:${cls.roomNo}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [_buildCodeBadge(cls.classCode, primary)]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _buildCodeBadge(String code, Color primary) => Container(
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
        Text(code, style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Color _tint(Color color, double amount) => Color.lerp(color, Colors.white, amount) ?? color;
  Color _soften(Color color, double amount) => Color.lerp(color, Colors.white, amount) ?? color;

  Widget _buildShimmerCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 6))],
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
                Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: double.infinity, height: 16, color: Colors.white),
                      const SizedBox(height: 6),
                      Row(children: [
                        Container(width: 60, height: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Container(width: 40, height: 16, color: Colors.white),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(children: [Container(width: 80, height: 14, color: Colors.white), const SizedBox(width: 16), Container(width: 60, height: 14, color: Colors.white)]),
            const SizedBox(height: 8),
            Container(width: 100, height: 14, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}