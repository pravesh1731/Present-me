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

class _CreateClassState extends State<CreateClass> {
  final GetStorage _storage = GetStorage();
  int _selectedTab = 0;

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

  @override
  void initState() {
    super.initState();
    final token = _getToken();
    if (token.isNotEmpty) {
      context.read<TeacherClassBloc>().add(TeacherFetchClasses(token));
    }
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: BlocBuilder<TeacherClassBloc, TeacherClassState>(
                builder: (context, state) {
                  if (state is TeacherClassLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is TeacherClassLoaded) {
                    if (state.classes.isEmpty) {
                      return const Center(child: Text('No Classes'));
                    }

                    return ListView.builder(
                      itemCount: state.classes.length,
                      itemBuilder: (_, i) =>
                          _buildClassCard(state.classes[i]),
                    );
                  }

                  if (state is TeacherClassError) {
                    return Center(child: Text(state.message));
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
        ),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'My Classes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================= TABS =================
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('Active'),
            selected: _selectedTab == 0,
            onSelected: (_) => setState(() => _selectedTab = 0),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Inactive'),
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
          onSelected: (v) {
            final token = _getToken();
            if (token.isEmpty) return;

            if (v == 'delete') {
              context.read<TeacherClassBloc>().add(
                TeacherDeleteClass(
                  token: token,
                  classCode: c.classCode,
                ),
              );
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
    final nameController =
    TextEditingController(text: existing?.className ?? '');
    final roomController =
    TextEditingController(text: existing?.roomNo ?? '');

    TimeOfDay? start = existing == null ? null : _parseTime(existing.startTime);
    TimeOfDay? end = existing == null ? null : _parseTime(existing.endTime);

    final selectedDays = <String>{
      ...?existing?.classDays.map(
            (d) => _dayMap.entries
            .firstWhere((e) => e.value == d)
            .key,
      ),
    };

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Create Class' : 'Edit Class'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
              ),
              TextField(
                controller: roomController,
                decoration: const InputDecoration(labelText: 'Room Number'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        start = await showTimePicker(
                          context: context,
                          initialTime: start ?? TimeOfDay.now(),
                        );
                        setState(() {});
                      },
                      child: Text(start == null
                          ? 'Start Time'
                          : _formatTime24(start)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        end = await showTimePicker(
                          context: context,
                          initialTime: end ?? TimeOfDay.now(),
                        );
                        setState(() {});
                      },
                      child:
                      Text(end == null ? 'End Time' : _formatTime24(end)),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: _dayMap.keys
                    .map(
                      (d) => FilterChip(
                    label: Text(d),
                    selected: selectedDays.contains(d),
                    onSelected: (v) => setState(() =>
                    v ? selectedDays.add(d) : selectedDays.remove(d)),
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
            onPressed: () {
              final token = _getToken();
              if (token.isEmpty) return;

              if (existing == null) {
                context.read<TeacherClassBloc>().add(
                  TeacherCreateClass(
                    token: token,
                    className: nameController.text.trim(),
                    roomNo: roomController.text.trim(),
                    startTime: _formatTime24(start),
                    endTime: _formatTime24(end),
                    classDays:
                    selectedDays.map((d) => _dayMap[d]!).toList(),
                  ),
                );
              } else {
                context.read<TeacherClassBloc>().add(
                  TeacherUpdateClass(
                    token: token,
                    classCode: existing.classCode,
                    className: nameController.text.trim(),
                    roomNo: roomController.text.trim(),
                    startTime: _formatTime24(start),
                    endTime: _formatTime24(end),
                    classDays:
                    selectedDays.map((d) => _dayMap[d]!).toList(),
                  ),
                );
              }

              Navigator.pop(context);
            },
            child: Text(existing == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }
}
