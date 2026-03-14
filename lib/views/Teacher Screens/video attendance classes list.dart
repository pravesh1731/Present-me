import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/viewmodels/teacher_class/teacher_class_bloc.dart';

class VideoAttendanceClasses extends StatefulWidget {
  const VideoAttendanceClasses({super.key});

  @override
  State<VideoAttendanceClasses> createState() => _VideoAttendanceClassesState();
}

class _VideoAttendanceClassesState extends State<VideoAttendanceClasses> {

  final GetStorage _storage = GetStorage();

  String _getToken() {
    return _storage.read('token')?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final token = _getToken();

      if (token.isNotEmpty) {
        context.read<TeacherClassBloc>().add(TeacherFetchClasses(token));
      }

    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFECFEFF),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF06B6D4),
                  Color(0xFF2563EB),
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
              children: [

                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 16),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'Video Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        'Select a class to mark attendance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// BODY
          Expanded(
            child: BlocBuilder<TeacherClassBloc, TeacherClassState>(
              builder: (context, state) {

                /// LOADING
                if (state is TeacherClassLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF06B6D4),
                    ),
                  );
                }

                /// LOADED
                if (state is TeacherClassLoaded) {

                  if (state.classes.isEmpty) {
                    return const Center(
                      child: Text(
                        "No classes found",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          "Active Classes (${state.classes.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: state.classes.length,
                          itemBuilder: (context, index) {

                            final classItem = state.classes[index];

                            final attendance = [94, 89, 91, 88][index % 4];
                            final students = [35, 28, 30, 32][index % 4];

                            return InkWell(

                              onTap: () {
                                // TODO: Navigate to Video Attendance Page
                              },

                              child: Container(

                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),

                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.07),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                  border: const Border(
                                    top: BorderSide(
                                      color: Color(0xFF10B981),
                                      width: 5,
                                    ),
                                  ),
                                ),

                                child: ListTile(

                                  leading: const Icon(
                                    Icons.menu_book_outlined,
                                    color: Color(0xFF10B981),
                                  ),

                                  title: Text(
                                    classItem.className ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),

                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Code: ${classItem.classCode ?? ""}"),
                                      const SizedBox(height: 4),
                                      Text("$students students"),
                                    ],
                                  ),

                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: attendance >= 90
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      "$attendance%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                /// ERROR
                if (state is TeacherClassError) {
                  return Center(
                    child: Text(
                      "Error: ${state.message}",
                      style: const TextStyle(color: Colors.red),
                    ),
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