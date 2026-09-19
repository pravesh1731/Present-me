import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mime/mime.dart';
import '../../../viewmodels/notes/notes_bloc.dart';
import '../../../viewmodels/notes/notes_event.dart';
import '../../../viewmodels/notes/notes_state.dart';
import 'download_manager.dart';
import 'downloaded_notes_screen.dart';
import 'pdf_viewer_screen.dart';

// ═══════════════════════════════════════════════════════════
// MODEL
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
  final String status;
  final String year;
  final String uploadedByName;
  final String rewardAmount;
  final String? description;

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
    required this.year,
    required this.uploadedByName,
    required this.rewardAmount,
    required this.description,
    this.status = 'pending',
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      noteId: json['noteId'] ?? '',
      title: json['fileName'] ?? '',
      type: json['type'] ?? '',
      semester: json['semester'] ?? '',
      department: json['department'] ?? '',
      teacher: json['teacherName'] ?? '',
      date: json['createdAt'] ?? '',
      downloads: json['downloads'] ?? 0,
      fileUrl: json['fileUrl'] ?? '',
      status: json['status'] ?? 'pending',
      year: json['year'] ?? '',
      uploadedByName: json['uploadedByName'] ?? 'Unknown',
        rewardAmount: json['rewardAmount']?.toString() ?? '',
        description: json['description'] ?? '',
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════

class NotesPyqsScreen extends StatefulWidget {
  const NotesPyqsScreen({super.key});

  @override
  State<NotesPyqsScreen> createState() => _NotesPyqsScreenState();
}

class _NotesPyqsScreenState extends State<NotesPyqsScreen> {
  int _selectedTab = 0;
  int _downloadType = 0;
  bool _isSearching = false;
  bool _hasSearched = false;

  List<NoteModel> _notes = [];
  final Set<String> _downloadingIds = {};

  String _filterCourse = 'B.Tech';
  String _filterSemester = '5th Semester';
  String _filterDepartment = 'Computer Science';

  String _uploadType = 'PYQ';
  String _uploadSemester = '5th Semester';
  String _uploadYear = '2025';
  String _uploadCourse = 'B.Tech';
  String _uploadDepartment = 'Computer Science';
  String _uploadSubject = '';

  final TextEditingController _teacherController = TextEditingController();

  File? _pickedFile;
  String? _pickedFileName;
  String? _pickedFileMime;

  final GetStorage _storage = GetStorage();

  String _getToken() => _storage.read('token')?.toString() ?? '';

  static const _semesters = [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
  ];

  static const _years = [
    '2024',
    '2025',
    '2026',
  ];

  static const _courses = [
    'B.Tech',
    // 'Science',
    // 'Arts',
    // 'Others',
  ];

  static const Map<String, List<String>> _deptMap = {
    'B.Tech': [
      'Artificial Intelligence',
      'Computer Science',
      'Information Technology',
      'Electronics & Communication',
      'Electrical',
      'Mechanical',
      'Industrial',
      'Civil',
      'Chemical',
      'VFX & Animation',
    ],
    'Science': [
      'Biotechnology',
      'Botany',
      'Chemistry',
      'Zoology',
      'B.Pharma',
      'M.Pharma',
    ],
    'Arts': [
      'B.Com',
      'BA in English',
      'Hindi',
      'Politics',
      'History',
      'Journalism & Mass Communication',
      'Economics',
      'Sociology',
    ],
    'Others': [
      'BA LLB',
      'B.Com LLB',
      'B.Ed',
      'M.Ed',
    ],
  };

  static const Map<String, Map<String, List<String>>> _subjectMap = {
    // ============================================================
    // COMPUTER SCIENCE & ENGINEERING
    // Current UI department name: Computer Science
    // ============================================================
    'Computer Science': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Programming for Problem Solving',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Data Structures',
        'Digital Logic Design',
        'Object-Oriented Programming',
        'Basic Electrical Engineering',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Discrete Mathematics',
        'Computer Organization & Architecture',
        'Database Management Systems',
        'Operating Systems',
        'Computer Networks',
        'Design & Analysis of Algorithms',
      ],
      '4th Semester': [
        'Theory of Computation',
        'Software Engineering',
        'Compiler Design',
        'Web Technologies',
        'Microprocessors & Microcontrollers',
        'Probability & Statistics',
      ],
      '5th Semester': [
        'Artificial Intelligence',
        'Machine Learning',
        'Computer Graphics',
        'Distributed Systems',
        'Information Security',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Cloud Computing',
        'Big Data Analytics',
        'Mobile Application Development',
        'Internet of Things',
        'Software Testing',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Deep Learning',
        'Cyber Security',
        'Data Mining',
        'DevOps',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Natural Language Processing',
        'Generative AI',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // ARTIFICIAL INTELLIGENCE & DATA SCIENCE
    // Current UI department name: Artificial Intelligence
    // ============================================================
    'Artificial Intelligence': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Programming for Problem Solving',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Data Structures',
        'Object-Oriented Programming',
        'Digital Logic',
        'Probability & Statistics',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Linear Algebra',
        'Database Management Systems',
        'Design & Analysis of Algorithms',
        'Computer Organization',
        'Python Programming',
        'Data Visualization',
      ],
      '4th Semester': [
        'Probability & Statistical Methods',
        'Artificial Intelligence',
        'Machine Learning',
        'Operating Systems',
        'Computer Networks',
        'Data Mining',
      ],
      '5th Semester': [
        'Deep Learning',
        'Natural Language Processing',
        'Big Data Analytics',
        'Data Warehousing',
        'Computer Vision',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Reinforcement Learning',
        'Advanced Machine Learning',
        'Cloud Computing',
        'Time Series Analysis',
        'MLOps',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Generative AI',
        'Deep Learning Applications',
        'Business Intelligence',
        'Data Engineering',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Advanced AI',
        'AI Ethics',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // INFORMATION TECHNOLOGY
    // ============================================================
    'Information Technology': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Programming for Problem Solving',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Data Structures',
        'Digital Electronics',
        'Object-Oriented Programming',
        'Basic Electrical Engineering',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Discrete Mathematics',
        'Computer Organization',
        'Database Management Systems',
        'Operating Systems',
        'Computer Networks',
        'Probability & Statistics',
      ],
      '4th Semester': [
        'Design & Analysis of Algorithms',
        'Software Engineering',
        'Web Technology',
        'Theory of Computation',
        'Microprocessors & Microcontrollers',
        'System Analysis & Design',
      ],
      '5th Semester': [
        'Artificial Intelligence',
        'Machine Learning',
        'Information Security',
        'Cloud Computing',
        'Data Mining',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Big Data Analytics',
        'Mobile Computing',
        'Internet of Things',
        'Distributed Systems',
        'Software Testing',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Cyber Security',
        'DevOps',
        'Data Science',
        'Blockchain Technology',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Advanced Cloud Computing',
        'Generative AI',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // ELECTRONICS & COMMUNICATION
    // ============================================================
    'Electronics & Communication': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Basic Electrical Engineering',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Electronic Devices',
        'Circuit Theory',
        'Digital Logic Design',
        'Programming for Problem Solving',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Signals & Systems',
        'Analog Electronics',
        'Digital Electronics',
        'Electromagnetic Theory',
        'Network Theory',
        'Probability & Random Processes',
      ],
      '4th Semester': [
        'Communication Systems',
        'Microprocessors & Microcontrollers',
        'Control Systems',
        'Digital Signal Processing',
        'Analog Communication',
        'Electronic Measurements & Instrumentation',
      ],
      '5th Semester': [
        'Digital Communication',
        'VLSI Design',
        'Embedded Systems',
        'Antenna & Wave Propagation',
        'Microwave Engineering',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Wireless Communication',
        'Optical Communication',
        'IoT',
        'Semiconductor Devices',
        'Computer Networks',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Advanced VLSI',
        'RF & Microwave Engineering',
        'Satellite Communication',
        'Embedded System Design',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Advanced Communication Systems',
        '5G/6G Communication',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // ELECTRICAL
    // ============================================================
    'Electrical': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Basic Electrical Engineering',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Electrical Circuit Theory',
        'Electronic Devices',
        'Programming for Problem Solving',
        'Engineering Mechanics',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Electrical Machines-I',
        'Network Analysis',
        'Electromagnetic Fields',
        'Analog Electronics',
        'Digital Electronics',
        'Electrical Measurements',
      ],
      '4th Semester': [
        'Electrical Machines-II',
        'Power Systems-I',
        'Control Systems',
        'Signals & Systems',
        'Power Electronics',
        'Microprocessors & Microcontrollers',
      ],
      '5th Semester': [
        'Power Systems-II',
        'Electrical Drives',
        'Switchgear & Protection',
        'High Voltage Engineering',
        'Power System Analysis',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Renewable Energy Systems',
        'Electrical Machine Design',
        'Industrial Electronics',
        'Power System Protection',
        'Energy Management',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Smart Grid',
        'Electric Vehicles',
        'Advanced Power Electronics',
        'Power Quality',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'HVDC & FACTS',
        'Advanced Power Systems',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // MECHANICAL
    // ============================================================
    'Mechanical': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Engineering Mechanics',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Thermodynamics',
        'Material Science',
        'Manufacturing Processes',
        'Basic Electrical Engineering',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Fluid Mechanics',
        'Strength of Materials',
        'Theory of Machines',
        'Engineering Materials',
        'Manufacturing Technology',
        'Numerical Methods',
      ],
      '4th Semester': [
        'Heat Transfer',
        'Machine Design-I',
        'Thermodynamics-II',
        'Metrology & Measurements',
        'Manufacturing Technology-II',
        'Fluid Machinery',
      ],
      '5th Semester': [
        'Machine Design-II',
        'Internal Combustion Engines',
        'CAD/CAM',
        'Industrial Engineering',
        'Dynamics of Machinery',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Refrigeration & Air Conditioning',
        'Finite Element Analysis',
        'CNC & Automation',
        'Robotics & Automation',
        'Operations Research',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Automobile Engineering',
        'Additive Manufacturing',
        'Computational Fluid Dynamics',
        'Mechatronics',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Electric & Hybrid Vehicles',
        'Advanced Manufacturing',
        'Industrial Automation',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // INDUSTRIAL / PRODUCTION
    // ============================================================
    'Industrial': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Engineering Mechanics',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Manufacturing Processes',
        'Material Science',
        'Basic Electrical Engineering',
        'Programming for Problem Solving',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Production Technology-I',
        'Engineering Materials',
        'Strength of Materials',
        'Metrology & Measurements',
        'Manufacturing Technology',
        'Engineering Statistics',
      ],
      '4th Semester': [
        'Production Technology-II',
        'Machine Tools',
        'Operations Research',
        'Industrial Engineering',
        'CAD/CAM',
        'Quality Control',
      ],
      '5th Semester': [
        'Production Planning & Control',
        'Industrial Automation',
        'CNC Technology',
        'Operations Management',
        'Supply Chain Management',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Total Quality Management',
        'Lean Manufacturing',
        'Six Sigma',
        'Facility Planning',
        'Logistics Management',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Robotics & Automation',
        'Advanced Manufacturing',
        'Industrial IoT',
        'Engineering Economics',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Smart Manufacturing',
        'Industry 4.0',
        'Advanced Supply Chain Management',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // CIVIL
    // ============================================================
    'Civil': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Engineering Mechanics',
        'Engineering Graphics',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Surveying',
        'Building Materials',
        'Basic Electrical Engineering',
        'Engineering Geology',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Strength of Materials',
        'Fluid Mechanics',
        'Structural Analysis-I',
        'Geotechnical Engineering-I',
        'Building Construction',
        'Engineering Surveying',
      ],
      '4th Semester': [
        'Structural Analysis-II',
        'Concrete Technology',
        'Geotechnical Engineering-II',
        'Hydraulics',
        'Transportation Engineering-I',
        'Environmental Engineering-I',
      ],
      '5th Semester': [
        'Reinforced Cement Concrete Design',
        'Steel Structure Design',
        'Transportation Engineering-II',
        'Water Resources Engineering',
        'Environmental Engineering-II',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Foundation Engineering',
        'Irrigation Engineering',
        'Construction Management',
        'Estimation & Costing',
        'Structural Design',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Earthquake Engineering',
        'Advanced Concrete Structures',
        'Highway Engineering',
        'Remote Sensing & GIS',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Advanced Structural Engineering',
        'Sustainable Construction',
        'Smart Cities',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // CHEMICAL
    // ============================================================
    'Chemical': {
      '1st Semester': [
        'Engineering Mathematics-I',
        'Engineering Physics',
        'Engineering Chemistry',
        'Engineering Graphics',
        'Basic Electrical Engineering',
        'Communication Skills',
      ],
      '2nd Semester': [
        'Engineering Mathematics-II',
        'Material & Energy Balance',
        'Engineering Thermodynamics',
        'Fluid Mechanics',
        'Programming for Problem Solving',
        'Environmental Science',
      ],
      '3rd Semester': [
        'Heat Transfer',
        'Mass Transfer',
        'Chemical Engineering Thermodynamics',
        'Chemical Process Calculations',
        'Mechanical Operations',
        'Numerical Methods',
      ],
      '4th Semester': [
        'Chemical Reaction Engineering-I',
        'Process Heat Transfer',
        'Mass Transfer Operations-I',
        'Process Instrumentation',
        'Fluid Flow Operations',
        'Chemical Technology',
      ],
      '5th Semester': [
        'Chemical Reaction Engineering-II',
        'Mass Transfer Operations-II',
        'Process Control',
        'Process Equipment Design',
        'Petroleum Engineering',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Process Dynamics',
        'Transport Phenomena',
        'Biochemical Engineering',
        'Plant Design',
        'Industrial Safety',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Process Simulation',
        'Petrochemical Technology',
        'Environmental Engineering',
        'Process Optimization',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Advanced Process Control',
        'Energy Engineering',
        'Green Chemical Engineering',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },

    // ============================================================
    // VFX & ANIMATION
    // ============================================================
    'VFX & Animation': {
      '1st Semester': [
        'Fundamentals of Drawing',
        'Design Fundamentals',
        'Digital Art',
        'Introduction to Animation',
        'Computer Fundamentals',
        'Communication Skills',
      ],
      '2nd Semester': [
        '2D Animation',
        'Character Design',
        'Storyboarding',
        'Digital Illustration',
        'Photography',
        'Design & Composition',
      ],
      '3rd Semester': [
        '3D Modeling',
        'Texturing',
        'Lighting',
        'Rigging',
        '3D Animation',
        'Visual Storytelling',
      ],
      '4th Semester': [
        'Advanced 3D Animation',
        'Character Animation',
        'Rendering Techniques',
        'Visual Effects',
        'Compositing',
        'Sound Design',
      ],
      '5th Semester': [
        'Motion Graphics',
        'Advanced VFX',
        'Rotoscopy',
        'Match Moving',
        'Matte Painting',
        'Professional Elective-I',
      ],
      '6th Semester': [
        'Simulation & Dynamics',
        'Advanced Compositing',
        '3D Character Animation',
        'Virtual Production',
        'Game Art & Design',
        'Professional Elective-II',
      ],
      '7th Semester': [
        'Film Production',
        'Advanced Visual Effects',
        'CGI Production',
        'Portfolio Development',
        'Project-I',
        'Professional Elective-III',
      ],
      '8th Semester': [
        'Advanced VFX Production',
        'Animation Studio Practice',
        'Portfolio / Showreel',
        'Project-II',
        'Internship / Major Project',
        'Professional Elective-IV',
      ],
    },
  };

  List<String> get _uploadDepts =>
      _deptMap[_uploadCourse] ?? [];

  List<String> get _filterDepts =>
      _deptMap[_filterCourse] ?? [];

  List<String> get _uploadSubjects =>
      _subjectMap[_uploadDepartment]?[_uploadSemester] ?? [];



  static const Color primary = Color(0xFF2563EB);
  static const Color purple = Color(0xFF06B6D4);
  static const Color background = Color(0xFFF5F7FC);
  static const Color textDark = Color(0xFF111827);
  static const Color textGrey = Color(0xFF64748B);
  static const Color border = Color(0xFFE6EAF2);



  void _handleSearch() {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    context.read<NotesBloc>().add(
      FetchNotes(
        token: _getToken(),
        type: _downloadType == 0 ? 'PYQ' : 'Notes',
        course: _filterCourse,
        semester: _filterSemester,
        department: _filterDepartment,
      ),
    );
  }

  @override
  void dispose() {
    _teacherController.dispose();
    super.dispose();
  }

  Color _typeColor(String type) {
    return type == 'PYQ'
        ? const Color(0xFF059669)
        : primary;
  }

  Color _typeBg(String type) {
    return type == 'PYQ'
        ? const Color(0xFFECFDF5)
        : const Color(0xFFEEF2FF);
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotesBloc, NotesState>(
      listener: (context, state) {
        if (state is NotesUploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading...'),
                ],
              ),
              duration: Duration(seconds: 30),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        if (state is NotesFetchSuccess) {
          setState(() {
            _notes = state.notes;
            _isSearching = false;
            _hasSearched = true;
          });
        }

        if (state is NotesFetchError) {
          setState(() {
            _isSearching = false;
            _hasSearched = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }

        if (state is NotesUploadSuccess) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          setState(() {
            _pickedFile = null;
            _pickedFileName = null;
            _pickedFileMime = null;
            _teacherController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text('Submitted for approval!'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        if (state is NotesUploadError) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          if (state.isDuplicate) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Already Exists',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  state.message,
                  style: const TextStyle(
                    color: textGrey,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: background,
        body: Column(
          children: [
            Header1(
              heading: "Notes & PYQs",
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _buildMainTabToggle(),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? _buildDownloadTab()
                  : _buildUploadTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MAIN TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildMainTabToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _mainTab(
            icon: Icons.download_rounded,
            label: 'Download',
            index: 0,
          ),
          _mainTab(
            icon: Icons.cloud_upload_outlined,
            label: 'Upload',
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _mainTab({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [
                primary,
                purple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? [
              BoxShadow(
                color: primary.withOpacity(.20),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : textGrey,
                size: 21,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : textGrey,
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DOWNLOAD TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildDownloadTab() {
    return Column(
      children: [
        // Notes / PYQ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [

              _subTypeTab(
                label: 'PYQ',
                icon: Icons.menu_book_outlined,
                index: 0,
              ),
              const SizedBox(width: 10),
              _subTypeTab(
                label: 'Notes',
                icon: Icons.description_outlined,
                index: 1,
              ),

            ],
          ),
        ),

        const SizedBox(height: 12),

        // Filter card
        _buildDownloadFilters(),


        // Content
        Expanded(
          child: _notes.isEmpty
              ? (_hasSearched
              ? _buildNoStudyMaterialState()
              : _buildInitialStateImage())
              : GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 20),
            physics: const BouncingScrollPhysics(),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 11,
              mainAxisSpacing: 11,
              childAspectRatio: 0.74,
            ),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              return _buildGridCard(_notes[index]);
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DOWNLOAD FILTERS
  // ═══════════════════════════════════════════════════════════

  Widget _buildDownloadFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: primary,
                size: 19,
              ),
              const SizedBox(width: 8),
              const Text(
                'Find study material',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniDropdown(
                  value: _filterCourse,
                  items: _courses,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _filterCourse = value;
                      _filterDepartment =
                          _deptMap[value]!.first;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniDropdown(
                  value: _filterSemester,
                  items: _semesters,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _filterSemester = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _miniDropdown(
                  value: _filterDepartment,
                  items: _filterDepts,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _filterDepartment = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSearching ? null : _handleSearch,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: _isSearching
                        ? LinearGradient(
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade500,
                      ],
                    )
                        : const LinearGradient(
                      colors: [
                        Color(0xFF2563EB),
                        Color(0xFF06B6D4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isSearching
                        ? const SizedBox(
                      key: ValueKey('loader'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      key: ValueKey('search'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 17,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SUB TYPE TAB
  // ═══════════════════════════════════════════════════════════

  Widget _subTypeTab({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final selected = _downloadType == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _downloadType = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? primary : border,
              width: selected ? 1.7 : 1,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: primary.withOpacity(.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? primary : textGrey,
                size: 20,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : textGrey,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MINI DROPDOWN
  // ═══════════════════════════════════════════════════════════

  Widget _miniDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 19,
            color: textGrey,
          ),
          style: const TextStyle(
            fontSize: 12,
            color: textDark,
            fontWeight: FontWeight.w600,
          ),
          items: items.map(
                (item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════

  Widget _buildInitialStateImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      child: Image.asset(
        'assets/image/adBanner.jpeg',
        width: double.infinity,
      ),
    );
  }

  Widget _buildNoStudyMaterialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEEF2FF),
                    Color(0xFFF5F3FF),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: primary,
                size: 37,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No study material found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Choose your course, semester and department\nthen tap Search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                height: 1.5,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // GRID CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildGridCard(NoteModel note) {
    final isPyq = note.type == 'PYQ';

    final iconBg = isPyq
        ? const Color(0xFFECFDF5)
        : const Color(0xFFEEF2FF);

    final iconColor = isPyq
        ? const Color(0xFF059669)
        : primary;

    final typeIcon = isPyq
        ? Icons.menu_book_rounded
        : Icons.description_rounded;

    final isDownloaded =
    DownloadManager.isDownloaded(note.noteId);

    final isDownloading =
    _downloadingIds.contains(note.noteId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File icon + type
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeIcon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const Spacer(),
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _typeBg(note.type),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    note.type,
                    style: TextStyle(
                      color: _typeColor(note.type),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: 4,),
                Text(
                  note.year,
                  style: const TextStyle(
                    fontSize: 10,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,

                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],)


            ],
          ),

          const SizedBox(height: 10),

          // Title

          Text(
            note.title,
            style: const TextStyle(
              fontSize: 12,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.w800,
              color: textDark,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Semester
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                size: 12,
                color: textGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  note.semester,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Teacher
          if (note.teacher != null && note.teacher!.trim().isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.book_outlined,
                  size: 12,
                  color: textGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    note.teacher!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 12,
                color: textGrey,
              ),
              const SizedBox(width: 4),
              Row(
                children: [
                  Text("By: ",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Text(
                  note.uploadedByName,
                  style: const TextStyle(
                    fontSize: 10,
                    color: textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),




          const SizedBox(height: 5),

          // Downloads
          Row(
            children: [
              const Icon(
                Icons.download_rounded,
                size: 12,
                color: primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${note.downloads}',
                style: const TextStyle(
                  fontSize: 10,
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isDownloaded) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 9,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 8,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Action
          GestureDetector(
            onTap: isDownloading
                ? null
                : isDownloaded
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    localPath:
                    DownloadManager.getLocalPath(
                      note.noteId,
                    )!,
                    title: note.title,
                  ),
                ),
              );
            }
                : () async {
              setState(
                    () => _downloadingIds.add(
                  note.noteId,
                ),
              );

              try {
                await DownloadManager.download(
                  noteId: note.noteId,
                  title: note.title,
                  type: note.type,
                  semester: note.semester,
                  department: note.department,
                  teacher: note.teacher,
                  fileUrl: note.fileUrl,
                  token: _getToken(),
                  year: note.year,
                  uploadedByName: note.uploadedByName,
                  onProgress: (received, total) {},
                );

                setState(() {});

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Saved for offline reading',
                        ),
                      ],
                    ),
                    backgroundColor:
                    Colors.green.shade700,
                    behavior:
                    SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    margin:
                    const EdgeInsets.all(14),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Download failed: ${e.toString().replaceFirst('Exception: ', '')}',
                    ),
                    backgroundColor:
                    Colors.red.shade700,
                    behavior:
                    SnackBarBehavior.floating,
                  ),
                );
              } finally {
                setState(
                      () => _downloadingIds.remove(
                    note.noteId,
                  ),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 9,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDownloaded
                      ? [
                    const Color(0xFF059669),
                    const Color(0xFF10B981),
                  ]
                      : isDownloading
                      ? [
                    Colors.grey.shade400,
                    Colors.grey.shade500,
                  ]
                      : [
                    primary,
                    purple,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  if (!isDownloading)
                    BoxShadow(
                      color: (isDownloaded
                          ? const Color(0xFF059669)
                          : primary)
                          .withOpacity(.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: isDownloading
                  ? const Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Saving...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    isDownloaded
                        ? Icons.open_in_new_rounded
                        : Icons.download_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isDownloaded ? 'Open' : 'Download',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UPLOAD TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildUploadTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
      physics: const BouncingScrollPhysics(),
      children: [
        // Main form
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              _buildSectionTitle(
                icon: Icons.category_outlined,
                title: 'Material Type',
                subtitle: 'Choose what you want to share',
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  _uploadTypeToggle(
                    label: 'PYQ',
                    icon: Icons.menu_book_rounded,
                  ),
                  const SizedBox(width: 10),
                  _uploadTypeToggle(
                    label: 'Notes',
                    icon: Icons.description_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSectionTitle(
                icon: Icons.school_outlined,
                title: 'Academic Details',
                subtitle: 'Tell us about this material',
              ),

              const SizedBox(height: 15),

              _fieldLabel('Course'),
              const SizedBox(height: 8),
              _dropdownField(
                value: _uploadCourse,
                items: _courses,
                icon: Icons.school_outlined,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _uploadCourse = value;
                    _uploadDepartment =
                        _deptMap[value]!.first;
                  });
                },
              ),

              const SizedBox(height: 17),

              _fieldLabel('Department'),
              const SizedBox(height: 8),
              _dropdownField(
                value: _uploadDepartment,
                items: _uploadDepts,
                icon: Icons.account_tree_outlined,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _uploadDepartment = value;

                    final subjects =
                        _subjectMap[value]?[_uploadSemester] ?? [];

                    _uploadSubject =
                    subjects.isNotEmpty ? subjects.first : '';
                  });
                },
              ),

              const SizedBox(height: 17),

              _fieldLabel('Semester'),
              const SizedBox(height: 8),
              _dropdownField(
                value: _uploadSemester,
                items: _semesters,
                icon: Icons.layers_outlined,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _uploadSemester = value;

                    final subjects =
                        _subjectMap[_uploadDepartment]?[value] ?? [];

                    _uploadSubject =
                    subjects.isNotEmpty ? subjects.first : '';
                  });
                },
              ),



              const SizedBox(height: 17),

              _fieldLabel('Academic Year'),
              const SizedBox(height: 8),
              _dropdownField(
                value: _uploadYear,
                items: _years,
                icon: Icons.calendar_month_outlined,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _uploadYear = value;
                  });
                },
              ),

              if (_uploadType == 'Notes') ...[
                const SizedBox(height: 17),

                _fieldLabel('Subject'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: _uploadSubject,
                  items: _uploadSubjects,
                  icon: Icons.menu_book_outlined,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _uploadSubject = value;
                    });
                  },
                ),
              ],


              const SizedBox(height: 24),

              _buildSectionTitle(
                icon: Icons.attach_file_rounded,
                title: 'Upload Document',
                subtitle: 'PDF, DOC, DOCX, PPT or PPTX • Max 10 MB',
              ),

              const SizedBox(height: 13),

              _buildFilePicker(),

              const SizedBox(height: 22),

              _buildSubmitButton(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Information card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFFDE68A),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFD97706),
                size: 19,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your uploaded material will be reviewed before it becomes available to other students.',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════════════

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: textGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UPLOAD TYPE
  // ═══════════════════════════════════════════════════════════

  Widget _uploadTypeToggle({
    required String label,
    required IconData icon,
  }) {
    final selected = _uploadType == label;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(
              () => _uploadType = label,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
              colors: [
                Color(0xFFEEF2FF),
                Color(0xFFF5F3FF),
              ],
            )
                : null,
            color: selected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? primary : border,
              width: selected ? 1.7 : 1,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: primary.withOpacity(.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: selected ? primary : textGrey,
                  size: 23,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : textGrey,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label == 'Notes'
                    ? 'Class material'
                    : 'Previous papers',
                style: TextStyle(
                  color: selected
                      ? primary.withOpacity(.65)
                      : textGrey.withOpacity(.75),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FIELD LABEL
  // ═══════════════════════════════════════════════════════════

  Widget _fieldLabel(String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DROPDOWN FIELD
  // ═══════════════════════════════════════════════════════════

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    IconData? icon,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: textGrey,
          ),
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: items.map(
                (item) {
              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: textGrey,
                      ),
                      const SizedBox(width: 9),
                    ],
                    Expanded(
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // INPUT
  // ═══════════════════════════════════════════════════════════

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType =
        TextInputType.text,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 13,
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
          prefixIcon,
          color: textGrey,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FILE PICKER
  // ═══════════════════════════════════════════════════════════

  Widget _buildFilePicker() {
    final hasFile = _pickedFile != null;

    return GestureDetector(
      onTap: () async {
        final result =
        await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'ppt',
            'pptx',
          ],
          withData: false,
        );

        if (result != null &&
            result.files.single.path != null) {
          setState(() {
            _pickedFile = File(
              result.files.single.path!,
            );
            _pickedFileName =
                result.files.single.name;
            _pickedFileMime =
                lookupMimeType(
                  result.files.single.path!,
                ) ??
                    'application/pdf';
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile
              ? const Color(0xFFEEF2FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: hasFile ? primary : border,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasFile
                    ? Colors.white
                    : const Color(0xFFEFF2F7),
                borderRadius:
                BorderRadius.circular(13),
              ),
              child: Icon(
                hasFile
                    ? Icons.insert_drive_file_rounded
                    : Icons.cloud_upload_outlined,
                color: hasFile
                    ? primary
                    : textGrey,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile
                        ? 'File selected'
                        : 'Choose a file',
                    style: TextStyle(
                      color: hasFile
                          ? textDark
                          : textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile
                        ? (_pickedFileName ?? '')
                        : 'Tap to browse your device',
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasFile
                          ? primary
                          : textGrey,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _pickedFile = null;
                    _pickedFileName = null;
                    _pickedFileMime = null;
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: textGrey,
                    size: 17,
                  ),
                ),
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: textGrey,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SUBMIT BUTTON
  // ═══════════════════════════════════════════════════════════

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            purple,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          final isUploading = state is NotesUploading;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),

              onTap: isUploading
                  ? null
                  : () async {
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) {
                    final bool isPyq = _uploadType == 'PYQ';

                    return Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight:
                          MediaQuery.of(context).size.height * .85,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                // HEADER
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient:
                                        const LinearGradient(
                                          colors: [
                                            primary,
                                            purple,
                                          ],
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isPyq
                                            ? Icons.menu_book_rounded
                                            : Icons
                                            .description_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Text(
                                        isPyq
                                            ? 'Before Uploading PYQ'
                                            : 'Before Uploading Notes',
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),

                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(
                                          dialogContext,
                                          false,
                                        );
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                          const Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 19,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // WARNING
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7E6),
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFD97706),
                                        size: 22,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Please make sure the uploaded '
                                              'material is complete, correct '
                                              'and belongs to the selected '
                                              'subject.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.45,
                                            color: Color(0xFF92400E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                const Text(
                                  'Submission Guidelines',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // =========================
                                // PYQ CONTENT
                                // =========================

                                if (isPyq) ...[
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                          const Color(0xFFEEF2FF),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: primary,
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Complete PYQ Coverage',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight.w700,
                                                color:
                                                Color(0xFF111827),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Make sure the uploaded PYQ '
                                                  'contains all examinations '
                                                  'for the selected semester.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.45,
                                                color:
                                                Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // CT1
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      const Color(0xFFF8FAFC),
                                      borderRadius:
                                      BorderRadius.circular(11),
                                      border: Border.all(
                                        color:
                                        const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.assignment_outlined,
                                          size: 18,
                                          color: primary,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'CT-1',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                            FontWeight.w700,
                                            color:
                                            Color(0xFF334155),
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(
                                          Icons.check_circle,
                                          color:
                                          Color(0xFF059669),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // CT2
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      const Color(0xFFF8FAFC),
                                      borderRadius:
                                      BorderRadius.circular(11),
                                      border: Border.all(
                                        color:
                                        const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.assignment_turned_in_outlined,
                                          size: 18,
                                          color: primary,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'CT-2',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                            FontWeight.w700,
                                            color:
                                            Color(0xFF334155),
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(
                                          Icons.check_circle,
                                          color:
                                          Color(0xFF059669),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // END SEM
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      const Color(0xFFF8FAFC),
                                      borderRadius:
                                      BorderRadius.circular(11),
                                      border: Border.all(
                                        color:
                                        const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.school_outlined,
                                          size: 18,
                                          color: primary,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'End Semester',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                            FontWeight.w700,
                                            color:
                                            Color(0xFF334155),
                                          ),
                                        ),
                                        Spacer(),
                                        Icon(
                                          Icons.check_circle,
                                          color:
                                          Color(0xFF059669),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                          const Color(0xFFEEF2FF),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.subject_rounded,
                                          color: primary,
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Particular Semester & Subject',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight.w700,
                                                color:
                                                Color(0xFF111827),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'All papers must belong to '
                                                  'the selected  '
                                                  'semester.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.45,
                                                color:
                                                Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ]

                                // =========================
                                // NOTES CONTENT
                                // =========================

                                else ...[
                                  Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color:
                                          const Color(0xFFEEF2FF),
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: primary,
                                          size: 19,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Complete Subject Notes',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                FontWeight.w700,
                                                color:
                                                Color(0xFF111827),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Make sure the notes cover '
                                                  'all the important topics '
                                                  'of the selected subject.',
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.45,
                                                color:
                                                Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color:
                                      const Color(0xFFF8FAFC),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                        const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.library_books_rounded,
                                          color: primary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'All topics of the subject '
                                                'should be covered. Do not '
                                                'upload notes containing '
                                                'only one or a few topics.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.5,
                                              color:
                                              Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color:
                                      const Color(0xFFF8FAFC),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                        const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: const Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.topic_rounded,
                                          color: primary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'The uploaded file should '
                                                'contain the complete '
                                                'available study material '
                                                'for that subject.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.5,
                                              color:
                                              Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // =========================
                                // REWARD WARNING
                                // =========================

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                      const Color(0xFFFFCDD4),
                                    ),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.card_giftcard_rounded,
                                        color: Color(0xFFE11D48),
                                        size: 21,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Important: If any incomplete content '
                                              'is found, the reward will '
                                              'not be given.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.5,
                                            color: Color(0xFF9F1239),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // =========================
                                // CONTINUE
                                // =========================

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient:
                                      const LinearGradient(
                                        colors: [
                                          primary,
                                          purple,
                                        ],
                                      ),
                                      borderRadius:
                                      BorderRadius.circular(13),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(
                                          dialogContext,
                                          true,
                                        );
                                      },
                                      style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.transparent,
                                        shadowColor:
                                        Colors.transparent,
                                        elevation: 0,
                                        shape:
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(
                                              13),
                                        ),
                                      ),
                                      child: const Text(
                                        'I Understand & Continue',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 5),

                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        dialogContext,
                                        false,
                                      );
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );

                // Only submit after confirmation
                if (confirmed == true && mounted) {
                  _handleSubmit();
                }
              },

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: isUploading
                      ? const [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Uploading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ]
                      : const [
                    Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Submit for Approval',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════
  // SUBMIT LOGIC — UNCHANGED
  // ═══════════════════════════════════════════════════════════

  void _handleSubmit() {

    if ( _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please fill all fields and choose a file',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(14),
        ),
      );
      return;
    }

    context.read<NotesBloc>().add(
      UploadNote(
        token: _getToken(),
        type: _uploadType,
        semester: _uploadSemester,
        year: _uploadYear,
        course: _uploadCourse,
        department: _uploadDepartment,
        teacherName:
        _uploadType == 'Notes'
            ? _uploadSubject
            : null,
        file: _pickedFile!,
        fileName: _pickedFileName!,
        mimeType: _pickedFileMime!,
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// PREMIUM HEADER
// ═══════════════════════════════════════════════════════════

class Header1 extends StatelessWidget {
  final String heading;
  final Color? backgroundColor1;
  final Color? backgroundColor2;

  const Header1({
    super.key,
    required this.heading,
    this.backgroundColor1,
    this.backgroundColor2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        bottom: 22,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor1 ?? const Color(0xFF06B6D4),
            backgroundColor2 ?? const Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─────────────────────────────
          // Back Button
          // ─────────────────────────────
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),



          const SizedBox(width: 12),

          // ─────────────────────────────
          // Heading
          // ─────────────────────────────
          Expanded(
            child: Text(
              heading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),

          // ─────────────────────────────
          // Small decorative icon
          // ─────────────────────────────
          InkWell(
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DownloadedNotesScreen(),
                ),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}