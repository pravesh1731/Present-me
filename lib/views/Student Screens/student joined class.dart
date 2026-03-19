import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  String? _lastAction;

  // Cache last loaded classes to avoid replacing UI on transient action/error states
  List<StudentClassModel> _cachedClasses = [];

  // Mock current user id (replace with your auth integration later)
  final String currentUserId = 'demo_user';

  // ================= TOKEN =================
  String _getToken() {
    return _storage.read('token')?.toString() ?? '';
  }

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
      // fallback: return first 3 chars, capitalized first letter
      final s = fullDay.trim();
      if (s.length <= 3) return s;
      return s.substring(0, 3);
    }
  }

  // Palette: flattened list of colors — we'll pick two adjacent colors per card
  static const List<Color> _classColors = [
    Color(0xFF10B981), Color(0xFF059669), // emerald
    Color(0xFF6366F1), Color(0xFF4F46E5), // indigo
    Color(0xFF8B5CF6), Color(0xFF7C3AED), // violet
    Color(0xFFF59E0B), Color(0xFFD97706), // amber
    Color(0xFFEF4444), Color(0xFFDC2626), // red
    Color(0xFF14B8A6), Color(0xFF0D9488), // teal
    Color(0xFF06B6D4), Color(0xFF0891B2), // cyan
    Color(0xFFA855F7), Color(0xFF9333EA), // purple
    Color(0xFF3B82F6), Color(0xFF2563EB), // blue
    Color(0xFFF97316), Color(0xFFEA580C), // orange
  ];

  @override
  void initState() {
    super.initState();
    // Try to dispatch fetch only if a StudentClassBloc is already provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final token = _getToken();
        if (token.isNotEmpty) {
          // If a student_pending_class provider exists above, dispatch the event
          context.read<StudentClassBloc>().add(StudentFetchEnrolledClasses(token));
        }
      } catch (e) {
        // No student_pending_class provided above this widget — we'll create one in build()
      }
    });
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
                                final token = _getToken();
                                if (token.isEmpty) return;

                                // mark that the user triggered a join action so the UI can treat
                                // any resulting error as transient and avoid replacing the list
                                _lastAction = 'join';
                                context.read<StudentClassBloc>().add(
                                  StudentJoinClass(
                                    token: token,
                                    classCode: _codeController.text.trim(),
                                  ),
                                );
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


  @override
  Widget build(BuildContext context) {
    // Build the main scaffold first
    final scaffold = Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinClassDialog,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Join Class',
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
             builder: (context, state) {

              // If we've got a loaded state, update cache and render it
              if (state is StudentClassLoaded) {
                // update cache (no setState since we're already building)
                _cachedClasses = List<StudentClassModel>.from(state.classes);

                if (state.classes.isEmpty) {
                  // still show header even if empty
                  return ListView(
                    padding: const EdgeInsets.only( bottom: 24),
                    children: [
                      _buildHeader(0),
                      const SizedBox(height: 24),
                      _buildEmptyState(),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24,),
                  itemCount: state.classes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeader(state.classes.length);
                    final cls = state.classes[index - 1];
                    return _buildClassCard(cls);
                  },
                );
              }

              //  Loading: if we have cached data, show it while loading; otherwise show shimmer
              if (state is StudentClassLoading) {
                if (_cachedClasses.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24,),
                    itemCount: _cachedClasses.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildHeader(_cachedClasses.length);
                      final cls = _cachedClasses[index - 1];
                      return _buildClassCard(cls);
                    },
                  );
                }

                // no cache -> show initial loading shimmer
                return ListView(
                  padding: const EdgeInsets.only( bottom: 24),
                  children: [
                    _buildHeader(0),
                    const SizedBox(height: 8),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                  ],
                );
              }

              //  Error: show only a snackbar (handled by listener) and keep showing cached data if any
              if (state is StudentClassError) {
                // We intentionally DON'T show the SnackBar here. The BlocListener
                // attached to the scaffold handles showing messages from actions.
                // Keep showing cached UI if available.
                if (_cachedClasses.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24,),
                    itemCount: _cachedClasses.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildHeader(_cachedClasses.length);
                      final cls = _cachedClasses[index - 1];
                      return _buildClassCard(cls);
                    },
                  );
                }

                // no cached data -> show error panel with retry
                return ListView(
                  padding: const EdgeInsets.only( bottom: 24),
                  children: [
                    _buildHeader(0),
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
                              if (token.isNotEmpty) context.read<StudentClassBloc>().add(StudentFetchEnrolledClasses(token));
                            },
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  ],
                );
              }

              //  Action success or other transient states: show cached UI if available and rely on listener for SnackBar
              if (state is StudentClassActionSuccess) {
                if (_cachedClasses.isNotEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24,),
                    itemCount: _cachedClasses.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildHeader(_cachedClasses.length);
                      final cls = _cachedClasses[index - 1];
                      return _buildClassCard(cls);
                    },
                  );
                }

                // no cache -> show empty state but keep dialog closed (listener does that)
                return
                  ListView(
                    padding: const EdgeInsets.only( bottom: 24),
                    children: [
                      _buildHeader(0),
                      const SizedBox(height: 24),
                      _buildEmptyState(),
                    ],
                  );
              }

              // Default: if we have cached data show it, otherwise empty box
              if (_cachedClasses.isNotEmpty) {
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24,),
                  itemCount: _cachedClasses.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeader(_cachedClasses.length);
                    final cls = _cachedClasses[index - 1];
                    return _buildClassCard(cls);
                  },
                );
              }

              return const SizedBox.shrink();
             },
           )

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
          if (token.isNotEmpty) {
            bloc.add(StudentFetchEnrolledClasses(token));
          }
          return bloc;
        },
        child: scaffold,
      );
    }

    return BlocListener<StudentClassBloc, StudentClassState>(
      listener: (context, state) {

        // ✅ JOIN CLASS SUCCESS
        if (state is StudentClassActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          _codeController.clear();

          // close join dialog if open
          Navigator.of(context, rootNavigator: true).pop();

          // clear last action marker after handling
          if (_lastAction == 'join') _lastAction = null;
        }

        // ❌ ERROR
        if (state is StudentClassError) {
          Fluttertoast.showToast(
            msg: state.message,
            gravity: ToastGravity.TOP,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );


          // clear last action marker after handling
          if (_lastAction == 'join') _lastAction = null;
        }
      },
      child: content, // 👈 VERY IMPORTANT
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
        borderRadius: const BorderRadius.only(
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
          Padding(
            padding: EdgeInsets.only(top: 8,right: 10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentJoinedClassScreen(),
                    ),
                  );

                },
                icon: const Icon(Icons.access_time),
              ),
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

  Widget _buildClassCard(StudentClassModel cls) {
    // determine theme from classCode for consistent colors across cards
    final Color primary = _classColors[(cls.classCode.hashCode) % _classColors.length];
    final Color secondary = _classColors[(cls.classCode.hashCode + 1) % _classColors.length];

    return GestureDetector(

          onTap: (){
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
                            Row(
                              children: [
                                Text(
                                  cls.className,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 10,),

                                Text(
                                  "(Prof. ${cls.teacherName}) ",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: cls.classDays.isNotEmpty
                                  ? cls.classDays.map((d) => _buildBadge(_shortFormFor(d))).toList()
                                  : [_buildBadge('No days')],
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
                  Row(
                    children: [
                      _buildCodeBadge(cls.classCode, primary),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 16,
                              color: Colors.white,
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
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
