import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mime/mime.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import '../../../viewmodels/notes/notes_bloc.dart';
import '../../../viewmodels/notes/notes_event.dart';
import '../../../viewmodels/notes/notes_state.dart';
   import 'download_manager.dart';
   import 'downloaded_notes_screen.dart';
import 'pdf_viewer_screen.dart';

// ═══════════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════════

class NoteModel {
  final String noteId;
  final String title;
  final String type;
  final String semester;
  final String department;
  final String teacher;
  final String date;
  final int downloads;
  final String fileUrl;
  final String status; // ✅ add this

  const NoteModel({
    required this.noteId,
    required this.title,
    required this.type,
    required this.semester,
    required this.department,
    required this.teacher,
    required this.date,
    required this.downloads,
    required this.fileUrl,
    this.status = 'pending', // ✅ default pending
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      noteId:     json['noteId']      ?? '',
      title:      json['fileName']    ?? '',
      type:       json['type']        ?? '',
      semester:   json['semester']    ?? '',
      department: json['department']  ?? '',
      teacher:    json['teacherName'] ?? 'Unknown',
      date:       json['createdAt']   ?? '',
      downloads:  json['downloads']   ?? 0,
      fileUrl:    json['fileUrl']     ?? '',
      status:     json['status']      ?? 'pending', // ✅ add this
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════

class NotesPyqsScreen extends StatefulWidget {
  const NotesPyqsScreen({super.key});

  @override
  State<NotesPyqsScreen> createState() => _NotesPyqsScreenState();
}

class _NotesPyqsScreenState extends State<NotesPyqsScreen> {
  int _selectedTab  = 0; // 0 = Download, 1 = Upload
  int _downloadType = 0; // 0 = Notes,    1 = PYQ

  List<NoteModel> _notes = [];
  final Set<String> _downloadingIds = {};

  // ── Download filter ──
  String _filterCourse     = 'B.Tech';
  String _filterSemester   = '5th Semester';
  String _filterDepartment = 'Computer Science';

  // ── Upload form ──
  String _uploadType       = 'Notes';
  String _uploadSemester   = '5th Semester';
  String _uploadYear       = '2025';
  String _uploadCourse     = 'B.Tech';
  String _uploadDepartment = 'Computer Science';
  final TextEditingController _teacherController = TextEditingController();

  File?   _pickedFile;
  String? _pickedFileName;
  String? _pickedFileMime;

  final GetStorage _storage = GetStorage();
  String _getToken() => _storage.read('token')?.toString() ?? '';

  static const _semesters = [
    '1st Semester','2nd Semester','3rd Semester','4th Semester',
    '5th Semester','6th Semester','7th Semester','8th Semester',
  ];
  static const _years   = ['2020','2021','2022','2023','2024','2025','2026'];
  static const _courses = ['B.Tech','Science','Arts','Others'];

  static const Map<String,List<String>> _deptMap = {
    'B.Tech':  ['Artificial Intelligence','Computer Science','Information Technology','Electronics & Communication','Electrical','Mechanical','Industrial','Civil','Chemical','VFX & Animation'],
    'Science': ['Biotechnology','Botany','Chemistry','Zoology','B.Pharma','M.Pharma'],
    'Arts':    ['B.Com','BA in English','Hindi','Politics','History','Journalism & Mass Communication','Economics','Sociology'],
    'Others':  ['BA LLB','B.Com LLB','B.Ed','M.Ed'],
  };

  List<String> get _uploadDepts => _deptMap[_uploadCourse]  ?? [];
  List<String> get _filterDepts => _deptMap[_filterCourse]  ?? [];

  void _handleSearch() {
    context.read<NotesBloc>().add(FetchNotes(
      token:      _getToken(),
      type:       _downloadType == 0 ? 'Notes' : 'PYQ',
      course:     _filterCourse,
      semester:   _filterSemester,
      department: _filterDepartment,
    ));
  }

  @override
  void dispose() {
    _teacherController.dispose();
    super.dispose();
  }

  Color _typeColor(String t) => t == 'PYQ' ? const Color(0xFF059669) : const Color(0xFF3B4FE0);
  Color _typeBg(String t)    => t == 'PYQ' ? const Color(0xFFD1FAE5) : const Color(0xFFEEF2FF);

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state is NotesUploading) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Row(children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Uploading...'),
            ]),
            duration: Duration(seconds: 30),
            behavior: SnackBarBehavior.floating,
          ));
        }
        if (state is NotesFetchSuccess) {
          setState(() => _notes = state.notes);
        }
        if (state is NotesFetchError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is NotesUploadSuccess) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          setState(() { _pickedFile = null; _pickedFileName = null; _pickedFileMime = null; _teacherController.clear(); });
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
                  TextButton(onPressed: () => Navigator.pop(context),
                      child: const Text('OK', style: TextStyle(color: Color(0xFF3B4FE0)))),
                ],
              ),
            );
            return;
          }
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildMainTabToggle(),
            ),
            Expanded(child: _selectedTab == 0 ? _buildDownloadTab() : _buildUploadTab()),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  MAIN TOGGLE
  // ═══════════════════════════════════════════════════════

  Widget _buildMainTabToggle() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        _mainTab(icon: Icons.download_rounded, label: 'Download', index: 0),
        _mainTab(icon: Icons.upload_rounded,   label: 'Upload',   index: 1),
      ]),
    );
  }

  Widget _mainTab({required IconData icon, required String label, required int index}) {
    final sel = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: sel ? const LinearGradient(colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            color: sel ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: sel ? Colors.white : Colors.black54, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: sel ? Colors.white : Colors.black54, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  DOWNLOAD TAB
  // ═══════════════════════════════════════════════════════

  Widget _buildDownloadTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadedNotesScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B4FE0).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.download_done_rounded, color: Color(0xFF3B4FE0), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'My Downloads',
                      style: TextStyle(
                        color: Color(0xFF3B4FE0),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // ✅ shows count of downloaded files
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B4FE0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${DownloadManager.getAllDownloaded().length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Color(0xFF3B4FE0), size: 18),
                ],
              ),
            ),
          ),
        ),
        // ── Notes / PYQ sub-toggle ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _subTypeTab(label: 'Notes', icon: Icons.description_outlined, index: 0),
            const SizedBox(width: 10),
            _subTypeTab(label: 'PYQ',   icon: Icons.menu_book_outlined,   index: 1),
          ]),
        ),
        const SizedBox(height: 12),

        // ── Filter card ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(children: [
                Expanded(child: _miniDropdown(value: _filterCourse, items: _courses, onChanged: (v) {
                  setState(() { _filterCourse = v!; _filterDepartment = _deptMap[v]!.first; });
                })),
                const SizedBox(width: 8),
                Expanded(child: _miniDropdown(value: _filterSemester, items: _semesters, onChanged: (v) {
                  setState(() => _filterSemester = v!);
                })),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _miniDropdown(value: _filterDepartment, items: _filterDepts, onChanged: (v) {
                  setState(() => _filterDepartment = v!);
                })),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSearch,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.search, color: Colors.white, size: 17),
                      SizedBox(width: 5),
                      Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 2-column grid ──
        Expanded(
          child: _notes.isEmpty
              ? const Center(
            child: Text(
              'No notes found.\nSelect filters and tap Search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black38, fontSize: 14),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:  2,
              crossAxisSpacing: 10,
              mainAxisSpacing:  10,
              childAspectRatio: 0.72,
            ),
            itemCount: _notes.length,
            itemBuilder: (ctx, i) => _buildGridCard(_notes[i]),
          ),
        ),
      ],
    );
  }

  Widget _subTypeTab({required String label, required IconData icon, required int index}) {
    final sel = _downloadType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _downloadType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? const Color(0xFF3B4FE0) : const Color(0xFFE2E8F0), width: sel ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: sel ? const Color(0xFF3B4FE0) : Colors.black38, size: 22),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(color: sel ? const Color(0xFF3B4FE0) : Colors.black38, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniDropdown({required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black45),
          style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  ✅ 2-COLUMN GRID CARD
  // ═══════════════════════════════════════════════════════

  Widget _buildGridCard(NoteModel note) {
    final isPyq      = note.type == 'PYQ';
    final iconBg     = isPyq ? const Color(0xFFD1FAE5) : const Color(0xFFEEF2FF);
    final iconColor  = isPyq ? const Color(0xFF059669) : const Color(0xFF3B4FE0);
    final typeIcon   = isPyq ? Icons.menu_book_outlined : Icons.description_outlined;
    final isDownloaded  = DownloadManager.isDownloaded(note.noteId);
    final isDownloading = _downloadingIds.contains(note.noteId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(typeIcon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),

          // title
          Text(
            note.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // badges
          Wrap(
            spacing: 4, runSpacing: 4,
            children: [
              _gridBadge(note.type,     _typeBg(note.type),      _typeColor(note.type)),
              _gridBadge(note.semester, const Color(0xFFF1F5F9), Colors.black45),
            ],
          ),
          const SizedBox(height: 6),

          // teacher
          Row(children: [
            const Icon(Icons.person_outline, size: 12, color: Colors.black38),
            const SizedBox(width: 4),
            Expanded(child: Text(note.teacher,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),

          // downloads count
          Row(children: [
            const Icon(Icons.download_rounded, size: 12, color: Color(0xFF3B4FE0)),
            const SizedBox(width: 4),
            Text('${note.downloads}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF3B4FE0), fontWeight: FontWeight.w600)),
            // ✅ Offline badge if already downloaded
            if (isDownloaded) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_pin_rounded, size: 9, color: Color(0xFF059669)),
                    SizedBox(width: 2),
                    Text('Saved', style: TextStyle(fontSize: 9, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ]),

          const Spacer(),

          // ✅ Button — changes based on state
          GestureDetector(
            onTap: isDownloading
                ? null // disabled while downloading
                : isDownloaded
            // ── Already downloaded → Open in viewer ──
                ? () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                localPath: DownloadManager.getLocalPath(note.noteId)!,
                title:     note.title,
              ),
            ))
            // ── Not downloaded → Download now ──
                : () async {
              setState(() => _downloadingIds.add(note.noteId));
              try {
                await DownloadManager.download(
                  noteId:     note.noteId,
                  title:      note.title,
                  type:       note.type,
                  semester:   note.semester,
                  department: note.department,
                  teacher:    note.teacher,
                  fileUrl:    note.fileUrl,
                  token:      _getToken(),
                  onProgress: (received, total) {
                    // progress callback (optional UI update)
                  },
                );
                setState(() {}); // refresh to show "Open" state
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Saved for offline reading'),
                  ]),
                  backgroundColor: Colors.green.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(12),
                ));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Download failed: ${e.toString().replaceFirst('Exception: ', '')}'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ));
              } finally {
                setState(() => _downloadingIds.remove(note.noteId));
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDownloaded
                      ? [const Color(0xFF059669), const Color(0xFF10B981)] // green = open
                      : isDownloading
                      ? [Colors.grey.shade400, Colors.grey.shade500]   // grey = loading
                      : [const Color(0xFF3B4FE0), const Color(0xFF6B4FE8)], // blue = download
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isDownloading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 6),
                  Text('Saving...', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDownloaded ? Icons.open_in_new_rounded : Icons.download_rounded,
                    color: Colors.white, size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isDownloaded ? 'Open' : 'Download',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridBadge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  // ═══════════════════════════════════════════════════════
  //  UPLOAD TAB (untouched)
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
              Row(children: const [
                Icon(Icons.upload_rounded, color: Color(0xFF3B4FE0), size: 22),
                SizedBox(width: 10),
                Text('Share Study Material', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              ]),
              const SizedBox(height: 24),
              _fieldLabel('Type'),
              const SizedBox(height: 10),
              Row(children: [
                _uploadTypeToggle(label: 'Notes', icon: Icons.description_outlined),
                const SizedBox(width: 12),
                _uploadTypeToggle(label: 'PYQ',   icon: Icons.menu_book_outlined),
              ]),
              const SizedBox(height: 20),
              _fieldLabel('Course'),
              const SizedBox(height: 10),
              _dropdownField(
                value: _uploadCourse, items: _courses,
                onChanged: (v) => setState(() { _uploadCourse = v!; _uploadDepartment = _deptMap[v]!.first; }),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Department'),
              const SizedBox(height: 10),
              _dropdownField(value: _uploadDepartment, items: _uploadDepts, onChanged: (v) => setState(() => _uploadDepartment = v!)),
              const SizedBox(height: 20),
              _fieldLabel('Semester'),
              const SizedBox(height: 10),
              _dropdownField(value: _uploadSemester, items: _semesters, onChanged: (v) => setState(() => _uploadSemester = v!)),
              const SizedBox(height: 20),
              _fieldLabel('Year'),
              const SizedBox(height: 10),
              _dropdownField(value: _uploadYear, items: _years, onChanged: (v) => setState(() => _uploadYear = v!)),
              const SizedBox(height: 20),
              if (_uploadType == 'Notes') ...[
                _fieldLabel('Teacher Name'),
                const SizedBox(height: 10),
                _inputField(controller: _teacherController, hint: 'e.g., Dr. John Smith'),
                const SizedBox(height: 20),
              ],
              _fieldLabel('Upload File'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf','doc','docx','ppt','pptx'],
                    withData: false,
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
                      color: _pickedFile != null ? const Color(0xFF3B4FE0) : const Color(0xFFE2E8F0),
                      width: _pickedFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_pickedFile != null ? Icons.insert_drive_file_outlined : Icons.attach_file_rounded,
                          color: _pickedFile != null ? const Color(0xFF3B4FE0) : Colors.black38, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        _pickedFileName ?? 'Choose file   No file chosen',
                        style: TextStyle(color: _pickedFileName != null ? const Color(0xFF111827) : Colors.black38, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      )),
                      if (_pickedFile != null)
                        GestureDetector(
                          onTap: () => setState(() { _pickedFile = null; _pickedFileName = null; _pickedFileMime = null; }),
                          child: const Icon(Icons.close, size: 18, color: Colors.black38),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xFF3B4FE0).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: BlocBuilder<NotesBloc, NotesState>(
                  builder: (context, state) {
                    final isUploading = state is NotesUploading;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isUploading ? null : _handleSubmit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: isUploading
                                ? const [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
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
  //  HELPERS
  // ═══════════════════════════════════════════════════════

  Widget _fieldLabel(String label) => Text('$label *',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54));

  Widget _uploadTypeToggle({required String label, required IconData icon}) {
    final sel = _uploadType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _uploadType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? const Color(0xFF3B4FE0) : const Color(0xFFE2E8F0), width: sel ? 2 : 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: sel ? const Color(0xFF3B4FE0) : Colors.black38, size: 26),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: sel ? const Color(0xFF3B4FE0) : Colors.black38, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B4FE0), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black54),
          style: const TextStyle(color: Color(0xFF111827), fontSize: 14, fontWeight: FontWeight.w500),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller, keyboardType: keyboardType,
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
      semester:    _uploadSemester,
      year:        _uploadYear,
      course:      _uploadCourse,
      department:  _uploadDepartment,
      teacherName: _uploadType == 'Notes' ? _teacherController.text.trim() : null,
      file:        _pickedFile!,
      fileName:    _pickedFileName!,
      mimeType:    _pickedFileMime!,
    ));
  }
}