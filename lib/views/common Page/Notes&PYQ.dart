import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mime/mime.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import '../../viewmodels/notes/notes_bloc.dart';
import '../../viewmodels/notes/notes_event.dart';
import '../../viewmodels/notes/notes_state.dart';

// ═══════════════════════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════════════════════

class NoteModel {
  final String title;
  final String type;
  final String semester;
  final String department;
  final String teacher;
  final String date;
  final int downloads;
  final String fileUrl;

  const NoteModel({
    required this.title,
    required this.type,
    required this.semester,
    required this.department,
    required this.teacher,
    required this.date,
    required this.downloads,
    required this.fileUrl,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      title: json['fileName'] ?? '',
      type: json['type'] ?? '',
      semester: json['semester'] ?? '',
      department: json['department'] ?? '',
      teacher: json['teacherName'] ?? 'Unknown',
      date: json['createdAt'] ?? '',
      downloads: json['downloads'] ?? 0,
      fileUrl: json['fileUrl'] ?? '',
    );
  }
}


// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════

class NotesPyqsScreen extends StatefulWidget {
  const NotesPyqsScreen({super.key});

  @override
  State<NotesPyqsScreen> createState() => _NotesPyqsScreenState();
}

class _NotesPyqsScreenState extends State<NotesPyqsScreen> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  List<NoteModel> _notes = [];

  // ── Upload form state ──
  String _uploadType         = 'Notes';
  String _selectedSemester   = '5th Semester';
  String _selectedYear       = '2025';
  String _selectedCourse     = 'B.Tech';
  String _selectedDepartment = 'Computer Science';
  final TextEditingController _teacherController = TextEditingController();

  // ✅ Real file state
  File?   _pickedFile;
  String? _pickedFileName;
  String? _pickedFileMime;

  final GetStorage _storage = GetStorage();
  String _getToken() => _storage.read('token')?.toString() ?? '';

  // ── Static lists ──
  static const _semesters = [
    '1st Semester', '2nd Semester', '3rd Semester', '4th Semester',
    '5th Semester', '6th Semester', '7th Semester', '8th Semester',
  ];

  static const _years = [
    '2020', '2021', '2022', '2023', '2024', '2025', '2026',
  ];

  static const _courses = ['B.Tech', 'Science', 'Arts', 'Others'];

  static const Map<String, List<String>> _departmentMap = {
    'B.Tech': [
      'Artificial Intelligence', 'Computer Science', 'Information Technology',
      'Electronics & Communication', 'Electrical', 'Mechanical',
      'Industrial', 'Civil', 'Chemical', 'VFX & Animation',
    ],
    'Science': [
      'Biotechnology', 'Botany', 'Chemistry', 'Zoology', 'B.Pharma', 'M.Pharma',
    ],
    'Arts': [
      'B.Com', 'BA in English', 'Hindi', 'Politics', 'History',
      'Journalism & Mass Communication', 'Economics', 'Sociology',
    ],
    'Others': ['BA LLB', 'B.Com LLB', 'B.Ed', 'M.Ed'],
  };

  List<String> get _currentDepartments => _departmentMap[_selectedCourse] ?? [];


  void _handleDownloadSearch() {
    context.read<NotesBloc>().add(
      FetchNotes(
        course: _selectedCourse,
        department: _selectedDepartment,
        semester: _selectedSemester,
        type: _uploadType, // ✅ IMPORTANT
        token: _getToken(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  Color _typeColor(String type) =>
      type == 'PYQ' ? const Color(0xFF10B981) : const Color(0xFF6366F1);

  Color _typeBg(String type) =>
      type == 'PYQ' ? const Color(0xFFD1FAE5) : const Color(0xFFEEF2FF);

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // ✅ BlocListener wraps the entire scaffold
    return BlocListener<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state is NotesUploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(children: [
                SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Uploading...'),
              ]),
              duration: Duration(seconds: 30),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is NotesFetchSuccess) {
          setState(() {
            _notes = state.notes;
          });
        }

        if (state is NotesFetchError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is NotesUploadSuccess) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          // ✅ Reset form after success
          setState(() {
            _pickedFile     = null;
            _pickedFileName = null;
            _pickedFileMime = null;
            _teacherController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Submitted for approval!'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ));
        }

        if (state is NotesUploadError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // ✅ Show warning dialog for duplicate
          if (state.isDuplicate) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 26),
                  SizedBox(width: 10),
                  Text('Already Exists'),
                ]),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Color(0xFF3B4FE0))),
                  ),
                ],
              ),
            );
            return;
          }

          // Regular error snackbar
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(state.message)),
            ]),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(12),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            Header(heading: "Notes & PYQs", subheading: "Download and share study materials"),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16),
              child: _buildTabToggle(),
            ),
            Expanded(
              child: _selectedTab == 0 ? _buildDownloadTab() : _buildUploadTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB TOGGLE (untouched)
  // ═══════════════════════════════════════════════════════

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton(icon: Icons.download_rounded, label: 'Download', index: 0),
          _tabButton(icon: Icons.upload_rounded,   label: 'Upload',   index: 1),
        ],
      ),
    );
  }

  Widget _tabButton({required IconData icon, required String label, required int index}) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.black54, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  DOWNLOAD TAB (untouched)
  // ═══════════════════════════════════════════════════════

  Widget _buildDownloadTab() {
    return Column(
      children: [
        Row(
          children: [
            _typeToggle(label: 'Notes', icon: Icons.description_outlined),
            const SizedBox(width: 10),
            _typeToggle(label: 'PYQ', icon: Icons.menu_book_outlined),
          ],
        ),
        const SizedBox(height: 10),
        // 🔹 Compact Filter Card
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [

              // Row 1 → Course + Semester
              Row(
                children: [
                  Expanded(
                    child: _compactDropdown(
                      value: _selectedCourse,
                      items: _courses,
                      hint: 'Course',
                      onChanged: (v) {
                        setState(() {
                          _selectedCourse = v!;
                          _selectedDepartment = _departmentMap[v]!.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _compactDropdown(
                      value: _selectedSemester,
                      items: _semesters,
                      hint: 'Semester',
                      onChanged: (v) =>
                          setState(() => _selectedSemester = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Row 2 → Department + Button
              Row(
                children: [
                  Expanded(
                    child: _compactDropdown(
                      value: _selectedDepartment,
                      items: _currentDepartments,
                      hint: 'Department',
                      onChanged: (v) =>
                          setState(() => _selectedDepartment = v!),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 🔍 Small Search Button
                  GestureDetector(
                    onTap: _handleDownloadSearch,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔽 Results (takes remaining space)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              if (_notes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'No notes found. Try searching.',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                )
              else
                ..._notes.map(_buildNoteCard).toList(),
            ],
          ),
        ),
      ],
    );
  }
  Widget _compactDropdown({
    required String value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          items: items
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(
              e,
              overflow: TextOverflow.ellipsis,
            ),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNoteCard(NoteModel note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  note.type == 'PYQ' ? Icons.menu_book_outlined : Icons.description_outlined,
                  color: const Color(0xFF3B4FE0), size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: [
                        _badge(note.type,       _typeBg(note.type),              _typeColor(note.type)),
                        _badge(note.semester,   const Color(0xFFF1F5F9),          Colors.black54),
                        _badge(note.department, const Color(0xFFD1FAE5),          const Color(0xFF059669)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // _infoRow(Icons.school_outlined,         note.subject),
          const SizedBox(height: 6),
          _infoRow(Icons.badge_outlined,          note.teacher),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_outlined, note.date),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.download_rounded, size: 16, color: Color(0xFF3B4FE0)),
              const SizedBox(width: 6),
              Text('${note.downloads} downloads',
                  style: const TextStyle(color: Color(0xFF3B4FE0), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFF3B4FE0).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Downloading ${note.title}...'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF3B4FE0),
                  ));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Download', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 15, color: Colors.black38),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13))),
    ],
  );

  // ═══════════════════════════════════════════════════════
  //  UPLOAD TAB
  // ═══════════════════════════════════════════════════════

  Widget _buildUploadTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.upload_rounded, color: Color(0xFF3B4FE0), size: 22),
                  const SizedBox(width: 10),
                  const Text('Share Study Material',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                ],
              ),
              const SizedBox(height: 24),

              // ── Type ──
              _fieldLabel('Type'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _typeToggle(label: 'Notes', icon: Icons.description_outlined),
                  const SizedBox(width: 12),
                  _typeToggle(label: 'PYQ',   icon: Icons.menu_book_outlined),
                ],
              ),
              const SizedBox(height: 20),

              // ── Course ──
              _fieldLabel('Course'),
              const SizedBox(height: 10),
              _dropdownField(
                value: _selectedCourse,
                items: _courses,
                onChanged: (v) {
                  setState(() {
                    _selectedCourse     = v!;
                    _selectedDepartment = _departmentMap[v]!.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              // ── Department ──
              _fieldLabel('Department'),
              const SizedBox(height: 10),
              _dropdownField(
                value: _selectedDepartment,
                items: _currentDepartments,
                onChanged: (v) => setState(() => _selectedDepartment = v!),
              ),
              const SizedBox(height: 20),

              // ── Semester ──
              _fieldLabel('Semester'),
              const SizedBox(height: 10),
              _dropdownField(
                value: _selectedSemester,
                items: _semesters,
                onChanged: (v) => setState(() => _selectedSemester = v!),
              ),
              const SizedBox(height: 20),

              // ── Year ──
              _fieldLabel('Year'),
              const SizedBox(height: 10),
              _dropdownField(
                value: _selectedYear,
                items: _years,
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
              const SizedBox(height: 20),

              // ── Teacher Name (Notes only) ──
              if (_uploadType == 'Notes') ...[
                _fieldLabel('Teacher Name'),
                const SizedBox(height: 10),
                _inputField(controller: _teacherController, hint: 'e.g., Dr. John Smith'),
                const SizedBox(height: 20),
              ],

              // ── Upload File ──
              _fieldLabel('Upload File'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
                    withData: false, // ✅ path only
                  );
                  if (result != null && result.files.single.path != null) {
                    setState(() {
                      _pickedFile     = File(result.files.single.path!);
                      _pickedFileName = result.files.single.name;
                      _pickedFileMime = lookupMimeType(result.files.single.path!) ?? 'application/pdf';
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      // ✅ highlight border when file is picked
                      color: _pickedFile != null
                          ? const Color(0xFF3B4FE0)
                          : const Color(0xFFE2E8F0),
                      width: _pickedFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pickedFile != null ? Icons.insert_drive_file_outlined : Icons.attach_file_rounded,
                        color: _pickedFile != null ? const Color(0xFF3B4FE0) : Colors.black38,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedFileName ?? 'Choose file   No file chosen',
                          style: TextStyle(
                            color: _pickedFileName != null ? const Color(0xFF111827) : Colors.black38,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_pickedFile != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _pickedFile     = null;
                            _pickedFileName = null;
                            _pickedFileMime = null;
                          }),
                          child: const Icon(Icons.close, size: 18, color: Colors.black38),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Submit button with loader ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xFF3B4FE0).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                // ✅ BlocBuilder just for the button state
                child: BlocBuilder<NotesBloc, NotesState>(
                  builder: (context, state) {
                    final isUploading = state is NotesUploading;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isUploading ? null : _handleSubmit, // ✅ disable while uploading
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: isUploading
                                ? const [
                              SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 10),
                              Text('Uploading...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            ]
                                : const [
                              Icon(Icons.upload_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('Submit for Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HELPERS (untouched)
  // ═══════════════════════════════════════════════════════

  Widget _fieldLabel(String label) => Text(
    '$label *',
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
  );

  Widget _typeToggle({required String label, required IconData icon}) {
    final selected = _uploadType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _uploadType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF3B4FE0) : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFF3B4FE0) : Colors.black38, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    color: selected ? const Color(0xFF3B4FE0) : Colors.black38,
                    fontWeight: FontWeight.w700, fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B4FE0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w500),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B4FE0), width: 1.5)),
      ),
    );
  }

  // ✅ Updated _handleSubmit — dispatches to bloc
  void _handleSubmit() {
    final teacherEmpty = _uploadType == 'Notes' && _teacherController.text.trim().isEmpty;

    if (teacherEmpty || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.error_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Please fill all fields and choose a file'),
        ]),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

    context.read<NotesBloc>().add(UploadNote(
      token:       _getToken(),
      type:        _uploadType,
      semester:    _selectedSemester,
      year:        _selectedYear,
      course:      _selectedCourse,
      department:  _selectedDepartment,
      teacherName: _uploadType == 'Notes' ? _teacherController.text.trim() : null,
      file:        _pickedFile!,
      fileName:    _pickedFileName!,
      mimeType:    _pickedFileMime!,
    ));
  }
}