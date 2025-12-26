import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'classDetailsStudentList.dart';
import 'package:present_me_flutter/src/repositories/teacherClass_repository.dart';
import 'package:present_me_flutter/src/models/class.dart';

class CreateClass extends StatefulWidget {
  const CreateClass({super.key});

  @override
  State<CreateClass> createState() => _CreateClassState();
}

class _CreateClassState extends State<CreateClass> {
  final TeacherClassRepository _repository = TeacherClassRepository();
  final GetStorage _storage = GetStorage();

  List<ClassModel> _classes = [];
  bool _loading = false;
  int _selectedTab = 0;

  // ================= TOKEN =================
  String _getToken() {
    const keys = [
      'token',
      'access_token',
      'authToken',
      'userToken',
      'teacher_token',
      'idToken'
    ];
    for (final k in keys) {
      final v = _storage.read(k);
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString();
      }
    }
    return '';
  }

  // ================= TIME FORMAT (HH:mm) =================
  String _formatTime24(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
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

  // ================= API =================
  Future<void> _loadClasses() async {
    final token = _getToken();
    if (token.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await _repository.getClasses(token);
      setState(() => _classes = data);
    } catch (e) {
      debugPrint('Load classes failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createClass({
    required String className,
    required String roomNo,
    required TimeOfDay? start,
    required TimeOfDay? end,
    required List<String> daysShort,
  }) async {
    final token = _getToken();
    if (token.isEmpty) return;

    final apiDays = daysShort.map((d) => _dayMap[d]!).toList();

    await _repository.createClass(
      token: token,
      className: className,
      roomNo: roomNo,
      startTime: _formatTime24(start),
      endTime: _formatTime24(end),
      classDays: apiDays,
    );

    await _loadClasses();
  }

  Future<void> _deleteClass(String classCode) async {
    final token = _getToken();
    if (token.isEmpty) return;

    await _repository.deleteClass(
      token: token,
      classCode: classCode,
    );

    await _loadClasses();
  }

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final activeClasses = _classes;
    final inactiveClasses = <ClassModel>[]; // backend doesn’t manage inactive yet
    final visible = _selectedTab == 0 ? activeClasses : inactiveClasses;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(activeClasses.length),
            _buildTabs(activeClasses.length, inactiveClasses.length),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                  ? const Center(child: Text('No Classes'))
                  : ListView.builder(
                itemCount: visible.length,
                itemBuilder: (_, i) => _buildClassCard(visible[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
        ),
      ),
      child: Column(
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
          const SizedBox(height: 6),
          Text(
            '$count active classes',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ================= TABS =================
  Widget _buildTabs(int active, int inactive) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: Text('Active ($active)'),
            selected: _selectedTab == 0,
            onSelected: (_) => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('Inactive ($inactive)'),
            selected: _selectedTab == 1,
            onSelected: (_) => setState(() => _selectedTab = 1),
          ),
        ],
      ),
    );
  }

  // ================= CARD =================
  Widget _buildClassCard(ClassModel c) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(c.className),
        subtitle: Text(
          '${c.roomNo} • ${c.classDays.join(', ')}\n${c.startTime} - ${c.endTime}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'delete') {
              await _deleteClass(c.classCode);
            } else if (v == 'edit') {
              _showEditDialog(c);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  classDetailsStudentList(classCode: c.classCode),
            ),
          );
        },
      ),
    );
  }

  // Helper: parse a HH:mm (24h) string into TimeOfDay, or null
  TimeOfDay? _parseTime24(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  // Helper: convert long day names to short keys used in UI chips
  List<String> _toShortDays(List<String> longDays) {
    final List<String> out = [];
    for (final ld in longDays) {
      final match = _dayMap.entries.firstWhere((e) => e.value.toLowerCase() == ld.toLowerCase(), orElse: () => const MapEntry('', ''));
      if (match.key.isNotEmpty) out.add(match.key);
    }
    return out;
  }

  // ================= EDIT DIALOG =================
  void _showEditDialog(ClassModel c) {
    final classNameController = TextEditingController(text: c.className);
    final roomController = TextEditingController(text: c.roomNo);
    TimeOfDay? start = _parseTime24(c.startTime);
    TimeOfDay? end = _parseTime24(c.endTime);
    final selectedDays = _toShortDays(c.classDays).toSet();

    final parentContext = context;
    showDialog(
      context: context,
      builder: (_) {
        bool isUpdating = false;
        return StatefulBuilder(builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Class'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: classNameController, decoration: const InputDecoration(labelText: 'Class Name')),
                  TextField(controller: roomController, decoration: const InputDecoration(labelText: 'Room Number')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(context: parentContext, initialTime: start ?? TimeOfDay.now());
                            if (t != null) setState(() => start = t);
                            // keep dialog state refreshed
                            setDialogState(() {});
                          },
                          child: Text(start == null ? 'Start Time' : _formatTime24(start)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final t = await showTimePicker(context: parentContext, initialTime: end ?? TimeOfDay.now());
                            if (t != null) setState(() => end = t);
                            setDialogState(() {});
                          },
                          child: Text(end == null ? 'End Time' : _formatTime24(end)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: _dayMap.keys.map((d) => FilterChip(
                      label: Text(d),
                      selected: selectedDays.contains(d),
                      onSelected: (v) {
                        setDialogState(() => v ? selectedDays.add(d) : selectedDays.remove(d));
                        // also update parent UI state if needed
                        setState(() {});
                      },
                    )).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                  final newName = classNameController.text.trim();
                  if (newName.isEmpty) return; // require a name

                  final apiDays = selectedDays.map((d) => _dayMap[d]!).toList();
                  final token = _getToken();
                  if (token.isEmpty) return;

                  setDialogState(() => isUpdating = true);
                  try {
                    await _repository.updateClass(
                      token: token,
                      classCode: c.classCode,
                      className: newName,
                      roomNo: roomController.text.trim(),
                      startTime: _formatTime24(start),
                      endTime: _formatTime24(end),
                      classDays: apiDays,
                    );
                    await _loadClasses();

                    // show success snackbar using parent context
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Class "$newName" updated'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Update class failed: $e');
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Update failed: ${e.toString()}'),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  } finally {
                    setDialogState(() => isUpdating = false);
                  }

                  if (mounted) Navigator.pop(dialogCtx);
                },
                child: isUpdating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update'),
              ),
            ],
          );
        });
      },
    );
  }

  // ================= CREATE DIALOG =================
  void _showCreateDialog() {
    final classNameController = TextEditingController();
    final roomController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final selectedDays = <String>{};

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Class'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: classNameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
              ),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Room Number'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (t != null) {
                          setState(() => startTime = t);
                        }
                      },
                      child: Text(
                        startTime == null
                            ? 'Start Time'
                            : _formatTime24(startTime),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (t != null) {
                          setState(() => endTime = t);
                        }
                      },
                      child: Text(
                        endTime == null
                            ? 'End Time'
                            : _formatTime24(endTime),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: _dayMap.keys
                    .map(
                      (d) => FilterChip(
                    label: Text(d),
                    selected: selectedDays.contains(d),
                    onSelected: (v) =>
                    v ? selectedDays.add(d) : selectedDays.remove(d),
                  ),
                )
                    .toList(),
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
            onPressed: () async {
              await _createClass(
                className: classNameController.text.trim(),
                roomNo: roomController.text.trim(),
                start: startTime,
                end: endTime,
                daysShort: selectedDays.toList(),
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
