import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:present_me_flutter/src/bloc/teacher_auth/teacher_auth_bloc.dart';
import 'package:present_me_flutter/src/repositories/teacherAuth_repository.dart';


class teacher_Profile extends StatefulWidget {
  @override
  State<teacher_Profile> createState() => _teacher_ProfileState();
}

class _teacher_ProfileState extends State<teacher_Profile> {
  final box = GetStorage();

  bool isLoading = true;
  bool isUploading = false;
  String? profilePicUrl;



  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final officeController = TextEditingController();
  final departmentController = TextEditingController();
  final specializationController = TextEditingController();
  final qualificationController = TextEditingController();
  final experienceController = TextEditingController();
  final employeeIdController = TextEditingController();
  
  String? joinedDate;
  int classesCount = 5;
  int studentsCount = 145;

  final ImagePicker _picker = ImagePicker();
  // When picking an image in edit modal, we store it here and only upload on Save
  File? _pendingPickedImage;

  // Return a NetworkImage only when `profilePicUrl` is a valid http/https URL.
  ImageProvider? _validNetworkImage() {
    final url = profilePicUrl?.trim();
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.scheme == 'http' || uri.scheme == 'https') return NetworkImage(url);
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Initialize from stored GetStorage (backwards compatibility) then try to populate from AuthBloc
    _loadFromStorage();
    // Listen for AuthAuthenticated to refresh UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<TeacherAuthBloc>().state;
      if (state is TeacherAuthAuthenticated) {
        _populateFromUserMap(state.teacher);
      }
    });
    // also subscribe to future state changes
    context.read<TeacherAuthBloc>().stream.listen((state) {
      if (state is TeacherAuthAuthenticated) {
        _populateFromUserMap(state.teacher);
      }
    });

  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    officeController.dispose();
    departmentController.dispose();
    specializationController.dispose();
    qualificationController.dispose();
    experienceController.dispose();
    employeeIdController.dispose();
    super.dispose();
  }


  void _loadFromStorage() {
    try {
      // Try to read the raw stored student JSON from GetStorage (may contain extra keys like profilePicUrl)
      final storedTeacherRaw = box.read('teacher');
      Map<String, dynamic>? storedTeacherMap;
      if (storedTeacherRaw != null) {
        try {
          if (storedTeacherRaw is Map<String, dynamic>) {
            storedTeacherMap = storedTeacherRaw;
          } else {
            storedTeacherMap = Map<String, dynamic>.from(storedTeacherRaw);
          }
        } catch (_) {
          storedTeacherMap = null;
        }
      }

      // Populate local controllers if storage present
      if (storedTeacherMap != null) {
        final fullName = ((storedTeacherMap['firstName'] ?? '') + ' ' + (storedTeacherMap['lastName'] ?? '')).trim();
        nameController.text = fullName;
        emailController.text = storedTeacherMap['emailId']?.toString() ?? '';
        phoneController.text = storedTeacherMap['phone']?.toString() ?? '';
        officeController.text = storedTeacherMap['officeLocation']?.toString() ?? '';
        departmentController.text = storedTeacherMap['department']?.toString() ?? '';
        specializationController.text = storedTeacherMap['specialization']?.toString() ?? '';
        qualificationController.text = storedTeacherMap['qualification']?.toString() ?? '';
        experienceController.text = storedTeacherMap['experience']?.toString() ?? '';
        employeeIdController.text = storedTeacherMap['empId']?.toString() ?? '';
        profilePicUrl = storedTeacherMap['profilePicUrl']?.toString()  ;
        final createdAt = storedTeacherMap['createdAt']?.toString() ?? '';
        if (createdAt.isNotEmpty) {
          try {
            final dt = DateTime.parse(createdAt);
            joinedDate = '${dt.day}-${dt.month}-${dt.year}';
          } catch (_) {
            joinedDate = createdAt;
          }
        }
      }


      classesCount = 0;

    } catch (e) {
      debugPrint('Error loading student from storage: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// local storage mai save karna..
  void _populateFromUserMap(Map<String, dynamic> user) {
    try {
      final firstName = (user['firstName'] ?? user['name']?.split(' ')?.first ?? '').toString();
      final lastName = (user['lastName'] ?? '').toString();
      final fullName = (firstName + ' ' + lastName).trim();

      nameController.text = fullName;
      emailController.text = (user['emailId'] ?? '').toString();
      phoneController.text = (user['phone'] ?? '').toString();
      officeController.text = (user['officeLocation'] ?? '').toString();
      departmentController.text = (user['department'] ?? '').toString();
      specializationController.text = (user['specialization'] ?? '').toString();
      qualificationController .text = (user['qualification'] ?? '').toString();
      experienceController.text = (user['experience'] ?? '').toString();
      employeeIdController.text = (user['empId'] ?? '').toString();
      profilePicUrl = (user['profilePicUrl'] ?? '').toString();
      final createdAt = (user['createdAt'] ?? user['created_at'] ?? '').toString();
      if (createdAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(createdAt);
          joinedDate = '${dt.day}-${dt.month}-${dt.year}';
        } catch (_) {
          joinedDate = createdAt;
        }
      }

      // persist merged map for offline use
      try {
        box.write('teacher', user);
      } catch (_) {}

      setState(() {});
    } catch (e) {
      debugPrint('populate error: $e');
    }
  }

  /// Save changes: patch profile on backend and update local state
  Future<void> saveChanges() async {
    // Build payload from form fields
    final token = box.read<String>('token');
    final Map<String, dynamic> payload = {
      'firstName': '',
      'lastName': '',
      'phone': phoneController.text.trim(),

      if (profilePicUrl != null && profilePicUrl!.trim().isNotEmpty) 'profilePicUrl': profilePicUrl,
      if (officeController.text.trim().isNotEmpty) 'officeLocation': officeController.text.trim(),
      if (departmentController.text.trim().isNotEmpty) 'department': departmentController.text.trim(),
      if (specializationController.text.trim().isNotEmpty) 'specialization': specializationController.text.trim(),
      if (qualificationController.text.trim().isNotEmpty) 'qualification': qualificationController.text.trim(),
      if (experienceController.text.trim().isNotEmpty) 'experience': experienceController.text.trim(),
      if (employeeIdController.text.trim().isNotEmpty) 'empId': employeeIdController.text.trim(),
    };

    final fullName = nameController.text.trim();
    if (fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      payload['firstName'] = parts.first;
      if (parts.length > 1) payload['lastName'] = parts.sublist(1).join(' ');
    }

    // If there is no token, persist locally and update UI only
    if (token == null || token.isEmpty) {
      final stored = box.read('teacher');
      final current = (stored is Map<String, dynamic>) ? Map<String, dynamic>.from(stored) : <String, dynamic>{};
      current.addAll(payload);
      try {
        box.write('teacher', current);
      } catch (_) {}
      _populateFromUserMap(current);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated locally (no token)')));
      return;
    }

    setState(() => isLoading = true);
    final repo = RepositoryProvider.of<TeacherAuthRepository>(context);
    try {
      // If there is a pending picked image, upload it first
      if (_pendingPickedImage != null) {
        final file = _pendingPickedImage!;
        final uploaded = await repo.uploadTeacherProfilePic(file);
        try {
          final Map<String, dynamic> uploadedMap = Map<String, dynamic>.from(uploaded);
          if (uploadedMap['profilePicUrl'] != null) {
            profilePicUrl = uploadedMap['profilePicUrl'].toString();
          } else if (uploadedMap['photoUrl'] != null) {
            profilePicUrl = uploadedMap['photoUrl'].toString();
          }
        } catch (e) {
          debugPrint('upload result handling error: $e');
        }
      }

      // Call repository.patchProfile directly
      final result = await repo.patchTeacherProfile(payload);
      // repository.patchProfile returns a Map<String,dynamic> on success
      final Map<String, dynamic> updated = Map<String, dynamic>.from(result);

      // Update UI and storage
      try {
        _populateFromUserMap(updated);
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green));

      // Notify bloc to refresh internal state
      try {
        context.read<TeacherAuthBloc>().add(TeacherFetchProfileRequested());
      } catch (_) {}
    } catch (e, st) {
      debugPrint('saveChanges -> patchProfile failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }





  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Photo Section
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: const Color(0xFF06B6D4),
                                  backgroundImage: _validNetworkImage(),
                                  child: _validNetworkImage() == null
                                      ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  setModalState(() => isUploading = true);
                                  try {
                                    final XFile? picked = await _picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 80,
                                    );
                                    if (picked == null) {
                                      setModalState(() => isUploading = false);
                                      return;
                                    }

                                    final file = File(picked.path);
                                    final repo = RepositoryProvider.of<TeacherAuthRepository>(context);

                                    // upload the image immediately
                                    final uploaded = await repo.uploadTeacherProfilePic(file);

                                    try {
                                      final Map<String, dynamic> uploadedMap = Map<String, dynamic>.from(uploaded);
                                      if (uploadedMap['profilePicUrl'] != null) {
                                        profilePicUrl = uploadedMap['profilePicUrl'].toString();
                                      } else if (uploadedMap['photoUrl'] != null) {
                                        profilePicUrl = uploadedMap['photoUrl'].toString();
                                      }
                                      _populateFromUserMap(uploadedMap);
                                      // Refresh bloc's internal state
                                      context.read<TeacherAuthBloc>().add(TeacherFetchProfileRequested());
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated'), backgroundColor: Colors.green));
                                    } catch (e) {
                                      debugPrint('upload result handling error: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload completed')));
                                    }
                                  } catch (e) {
                                    debugPrint('upload error: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                                  } finally {
                                    setModalState(() => isUploading = false);
                                    setState(() {});
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6D4),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Form Fields
                      _buildModalTextField('Full Name', nameController, Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildModalTextField('Email', emailController, Icons.email_outlined, enabled: false),
                      const SizedBox(height: 16),
                      _buildModalTextField('Phone Number', phoneController, Icons.phone_outlined),
                      const SizedBox(height: 16),
                      _buildModalTextField('Office Location', officeController, Icons.location_on_outlined),
                      const SizedBox(height: 16),
                      _buildModalTextField('Department', departmentController, Icons.business_outlined),
                      const SizedBox(height: 16),
                      _buildModalTextField('Specialization', specializationController, Icons.school_outlined),
                      const SizedBox(height: 16),
                      _buildModalTextField('Qualification', qualificationController, Icons.workspace_premium_outlined),
                      const SizedBox(height: 16),
                      _buildModalTextField('Years of Experience', experienceController, Icons.history_edu_outlined),
                      const SizedBox(height: 16),
                      _buildModalTextField('Employee ID', employeeIdController, Icons.badge_outlined),
                      const SizedBox(height: 32),
                      // Save Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await saveChanges();
                              Navigator.pop(context);
                            },
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalTextField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF06B6D4)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECFEFF),
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
            children: [
              // Header with gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)], // cyan-500 to blue-600
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Profile Card
            Transform.translate(
              offset: const Offset(0, -70),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Photo with edit badge
                        Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF06B6D4).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 58,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: const Color(0xFF06B6D4),
                                  backgroundImage:
                                  _validNetworkImage(),
                                  child: _validNetworkImage() == null
                                      ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                      : null,
                                ),
                              ),
                            ),

                          ],
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          nameController.text.isNotEmpty ? nameController.text : 'Prof. Name',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),

                        // Department
                        Text(
                          departmentController.text.isNotEmpty 
                              ? '${departmentController.text}'
                              : 'Department',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Senior Faculty Badge
                        if (experienceController.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              experienceController.text.contains('yr') 
                                  ? 'Senior Faculty'
                                  : 'Faculty',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Edit Profile Button
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06B6D4).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _showEditProfileModal,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 16),
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.class_outlined,
                            value: classesCount.toString(),
                            label: 'Classes',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people_outline,
                            value: studentsCount.toString(),
                            label: 'Students',
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.history_edu_outlined,
                            value: experienceController.text.isNotEmpty 
                                ? experienceController.text
                                : '0 yrs',
                            label: 'Experience',
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Personal Information Section
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Personal Information Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.email_outlined, 'Email', emailController.text),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.phone_outlined, 'Phone', phoneController.text.isNotEmpty ? phoneController.text : 'Not provided'),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.location_on_outlined, 'Office', officeController.text.isNotEmpty ? officeController.text : 'Not provided'),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Joined', joinedDate ?? 'Not available'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Professional Information Section
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Professional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Professional Information Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfessionalInfoRow('Employee ID', employeeIdController.text.isNotEmpty ? employeeIdController.text : 'Not provided'),
                        const SizedBox(height: 16),
                        _buildProfessionalInfoRow('Department', departmentController.text.isNotEmpty ? departmentController.text : 'Not provided'),
                        const SizedBox(height: 16),
                        _buildProfessionalInfoRow('Specialization', specializationController.text.isNotEmpty ? specializationController.text : 'Not provided'),
                        const SizedBox(height: 16),
                        _buildProfessionalInfoRow('Qualification', qualificationController.text.isNotEmpty ? qualificationController.text : 'Not provided'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Achievements Section
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Achievements Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildAchievementCard(
                                icon: Icons.military_tech_outlined,
                                title: 'Best Teacher',
                                year: '2024',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAchievementCard(
                                icon: Icons.workspace_premium_outlined,
                                title: 'Excellence Award',
                                year: '2022',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                 
                ],
              ),
            ),
          ],
        ),
      ),
      )
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard({required IconData icon, required String title, required String year}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFF7ED),
            const Color(0xFFFEF3C7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            year,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
