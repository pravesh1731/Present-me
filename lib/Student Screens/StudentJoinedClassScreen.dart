import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:present_me_flutter/src/bloc/studentPendingClass/student_pending_class_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/src/models/studentPendingClass.dart';
import 'package:shimmer/shimmer.dart';

class StudentJoinedClassScreen extends StatefulWidget {
  const StudentJoinedClassScreen({Key? key}) : super(key: key);

  @override
  State<StudentJoinedClassScreen> createState() =>
      _StudentJoinedClassScreenState();
}

class _StudentJoinedClassScreenState extends State<StudentJoinedClassScreen> {
  final GetStorage _storage = GetStorage();
  String? _lastErrorShown;

  String _getToken() {
    return _storage.read('token')?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final bloc = context.read<StudentPendingClassBloc>();
        final token = _getToken();
        if (token.isNotEmpty) {
          // Always refresh when the screen opens so newly joined requests appear
          bloc.add(StudentFetchPendingClasses(token));
        }
      } catch (_) {
        // No StudentPendingClassBloc found in the tree; caller should provide it.
      }
    });
  }



  static const List<List<Color>> _themes = [
    [Color(0xFF3B82F6), Color(0xFF2563EB)], // blue
    [Color(0xFFF97316), Color(0xFFF43F5E)], // orange/red
    [Color(0xFFA855F7), Color(0xFF7C3AED)], // purple
    [Color(0xFF06B6D4), Color(0xFF0891B2)], // cyan
    [Color(0xFF10B981), Color(0xFF059669)], // emerald
  ];

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
          child: BlocBuilder<StudentPendingClassBloc, StudentPendingClassState>(
            builder: (context, state) {
              if (state is StudentPendingClassLoading) {
                return ListView(
                  padding: const EdgeInsets.only( bottom: 24),
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 8),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                    _buildShimmerCard(),
                  ],
                );
              }

              if (state is StudentPendingClassError) {
                if (_lastErrorShown != state.message) {
                  _lastErrorShown = state.message;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(state.message)),
                          ],
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  });
                }

                return ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  children: [
                    const SizedBox(height: 24),
                    Center(
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
                              final token = _getToken();
                              if (token.isNotEmpty)
                                context.read<StudentPendingClassBloc>().add(
                                  StudentFetchPendingClasses(token),
                                );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              if (state is StudentPendingClassLoaded) {
                // Create a single scrollable list: header then one card per class
                final List<Widget> listChildren = [];
                listChildren.add(_buildHeader(context));
                listChildren.add(const SizedBox(height: 12));

                if (state.classes.isEmpty) {
                  listChildren.add(Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    child: _buildNoClasses(),
                  ));
                } else {
                  for (var i = 0; i < state.classes.length; i++) {
                    final cls = state.classes[i];
                    final theme = _themes[i % _themes.length];
                    listChildren.add(Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildRequestCard(theme, cls),
                    ));
                  }
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: listChildren,
                );
              }



              // Fallback return — ensure a Widget is always returned from the builder
              return ListView(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'No pending classes',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              );


            },
          )
        ),
      ),
    );
  }



    Widget _buildHeader(BuildContext context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 34, 18, 22),

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
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
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

  Widget _buildRequestCard(
      List<Color> theme,
      StudentPendingClassModel cls,) {
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
                            // use withAlpha to avoid deprecated channel access
                            color: primary.withAlpha((0.12 * 255).round()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.menu_book_outlined,
                            color: primary,
                            size: 26,
                          ),
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
                                      cls.className,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withAlpha((0.2 * 255).round()),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                       'Pending',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cls.teacherName,
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
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
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cls.roomNo ,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 18),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cls.classCode,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
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
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                           'Your request is waiting for teacher approval. You will be notified once it is reviewed.',
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontSize: 13,
                            ),
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
                        onPressed: (){},
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            'Cancel Request',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.class_, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'No classes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have not requested to join any classes yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class bodyHeader extends StatelessWidget {
  const bodyHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Awaiting Teacher Approval',
      style: TextStyle(
        color: Colors.grey.shade800,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

Widget _buildShimmerCard() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.03 * 255).round()),
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
