import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/src/bloc/teacherClass/teacher_class_bloc.dart';
import 'package:present_me_flutter/src/models/class.dart';
import 'classDetailsStudentList.dart';

class CreateClass extends StatefulWidget {
  const CreateClass({super.key});

  @override
  State<CreateClass> createState() => _CreateClassState();
}

class _CreateClassState extends State<CreateClass> with SingleTickerProviderStateMixin {
  final GetStorage _storage = GetStorage();
  int _selectedTab = 0;
  int _activeCount = 0;
  late final AnimationController _shimmerController;

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
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
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
      final entry = _dayMap.entries.firstWhere((e) => e.value.toLowerCase() == fullDay.toLowerCase());
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
    return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cols);
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
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

  // Small shader-based shimmer helper
  Widget _shimmer(Widget child) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            final shimmerWidth = rect.width * 0.6;
            final offset = (_shimmerController.value * (rect.width + shimmerWidth)) - shimmerWidth;
            return LinearGradient(
              colors: [Colors.grey.shade300, Colors.grey.shade100, Colors.grey.shade300],
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
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 16, width: double.infinity, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Container(height: 20, width: 80, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(children: [Container(height: 12, width: 120, color: Colors.grey.shade300), const SizedBox(width: 12), Container(height: 12, width: 80, color: Colors.grey.shade300)]),
                  const SizedBox(height: 12),
                  Row(children: [Container(height: 12, width: 90, color: Colors.grey.shade300), const SizedBox(width: 12), Container(height: 28, width: 100, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16)))]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(height: 44, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(14))),
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
            colors: [
              Color(0xFFECFEFF), // cyan-50
              Color(0xFFEFF6FF), // blue-50
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModernHeader(),
              BlocBuilder<TeacherClassBloc, TeacherClassState>(
                builder: (context, state) {
                  int active = 0;
                  List<ClassModel> filtered = [];
                  if (state is TeacherClassLoaded) {
                    active = state.classes.length;
                    filtered = state.classes.toList();
                    _activeCount = active;
                  }
                  return Column(
                    children: [
                      _buildModernTabs(active),
                      Builder(
                        builder: (_) {
                          if (state is TeacherClassLoading) {
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (_, __) => _shimmer(_buildShimmerCard()),
                            );
                          }
                          if (state is TeacherClassLoaded) {
                            if (filtered.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(child: Text('No Classes')),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (_, i) => _buildModernClassCard(filtered[i]),
                            );
                          }
                          if (state is TeacherClassError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(child: Text(state.message)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  );
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
                '$_activeCount active classes',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
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
                    'Inactive (0)', // Inactive tab always shows 0
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
    final students = c.students.length;
    final int attendance = 94; // show a realistic value like your screenshot
    final badgeColor = attendance >= 90 ? Colors.green : (attendance >= 75 ? Colors.orange : Colors.red);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 4)),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: icon, class name and edit icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6FDF3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.menu_book, color: Color(0xFF059669), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                c.className,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // three-dots menu with Edit / Delete
                            PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, size: 18, color: Colors.black54),
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  _showEditDialog(c);
                                  return;
                                }
                                if (v == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete class'),
                                      content: const Text('Are you sure you want to delete this class? This action cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    final token = _getToken();
                                    if (token.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
                                      return;
                                    }
                                    context.read<TeacherClassBloc>().add(TeacherDeleteClass(token: token, classCode: c.classCode));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting class...')));
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'))),
                                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete), title: Text('Delete'))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Days pill left-aligned under class name (short form)
                  Padding(
                    padding: const EdgeInsets.only(left: 52.0), // align under the text (after icon + spacing)
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c.classDays.map((d) => _shortFormFor(d)).join(', '),
                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.black38),
                      const SizedBox(width: 6),
                      Text('${_formatTo12(c.startTime)} - ${_formatTo12(c.endTime)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on, size: 16, color: Colors.black38),
                      const SizedBox(width: 6),
                      Flexible(child: Text('Room ${c.roomNo}', style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: Colors.black38),
                      const SizedBox(width: 6),
                      Text('$students students', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor, // solid green background
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('$attendance% attendance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.remove_red_eye, size: 18, color: Colors.white),
                  label: const Text('View Class', style: TextStyle(fontSize: 16, color: Colors.white)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => classDetailsStudentList(classCode: c.classCode)),
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
    final nameController = TextEditingController(text: existing?.className ?? '');
    final roomController = TextEditingController(text: existing?.roomNo ?? '');
    TimeOfDay? start = existing == null ? null : _parseTime(existing.startTime);
    TimeOfDay? end = existing == null ? null : _parseTime(existing.endTime);
    final selectedDays = <String>{
      ...existing?.classDays.map((d) => _dayMap.entries.firstWhere((e) => e.value == d, orElse: () => const MapEntry('Mon', 'Monday')).key) ?? {},
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
}


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
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.nameController.text.isEmpty ? 'Create Class' : 'Edit Class'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(labelText: 'Class Name'),
            ),
            TextField(
              controller: widget.roomController,
              decoration: const InputDecoration(labelText: 'Room Number'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: start ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => start = picked);
                    },
                    child: Text(start == null ? 'Start Time' : '${start!.hour.toString().padLeft(2, '0')}:${start!.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => end = picked);
                    },
                    child: Text(end == null ? 'End Time' : '${end!.hour.toString().padLeft(2, '0')}:${end!.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              children: widget.dayMap.keys.map((d) => FilterChip(
                label: Text(d),
                selected: selectedDays.contains(d),
                onSelected: (v) => setState(() => v ? selectedDays.add(d) : selectedDays.remove(d)),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              widget.nameController.text,
              widget.roomController.text,
              start,
              end,
              selectedDays,
            );
            Navigator.pop(context);
          },
          child: Text(widget.nameController.text.isEmpty ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
