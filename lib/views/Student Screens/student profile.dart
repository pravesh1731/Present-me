import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/studentAuth_repository.dart';
import '../../viewmodels/student_auth/auth_bloc.dart';
import '../../viewmodels/student_auth/auth_event.dart';
import '../../viewmodels/student_auth/auth_state.dart';
import '../../viewmodels/student_class/student_class_bloc.dart';


class student_Profile extends StatefulWidget {
  @override
  State<student_Profile> createState() => _student_ProfileState();
}

class _student_ProfileState extends State<student_Profile> {
  final box = GetStorage();

  bool isLoading = true;
  bool isUploading = false;
  String? profilePicUrl;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final rollController = TextEditingController();
  final semesterController = TextEditingController();
  final branchController = TextEditingController();
  final yearController = TextEditingController();
  final sectionController = TextEditingController();

  String? joinedDate;
  int classesCount = 0;
  double attendancePercentage = 0.0;

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
      final state = context.read<AuthBloc>().state;
      if (state is AuthAuthenticated) {
        _populateFromUserMap(state.student);
      }
    });
    // also subscribe to future state changes
    context.read<AuthBloc>().stream.listen((state) {
      if (state is AuthAuthenticated) {
        _populateFromUserMap(state.student);
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    rollController.dispose();
    semesterController.dispose();
    branchController.dispose();
    yearController.dispose();
    sectionController.dispose();
    super.dispose();
  }

  void _loadFromStorage() {
    try {
      // Try to read the raw stored student JSON from GetStorage (may contain extra keys like profilePicUrl)
      final storedStudentRaw = box.read('student');
      Map<String, dynamic>? storedStudentMap;
      if (storedStudentRaw != null) {
        try {
          if (storedStudentRaw is Map<String, dynamic>) {
            storedStudentMap = storedStudentRaw;
          } else {
            storedStudentMap = Map<String, dynamic>.from(storedStudentRaw);
          }
        } catch (_) {
          storedStudentMap = null;
        }
      }

      // Populate local controllers if storage present
      if (storedStudentMap != null) {
        final fullName =
            ((storedStudentMap['firstName'] ?? '') +
                    ' ' +
                    (storedStudentMap['lastName'] ?? ''))
                .trim();
        nameController.text = fullName;
        emailController.text = storedStudentMap['emailId']?.toString() ?? '';
        phoneController.text = storedStudentMap['phone']?.toString() ?? '';
        rollController.text = storedStudentMap['rollNo']?.toString() ?? '';
        semesterController.text =
            storedStudentMap['semester']?.toString() ?? '';
        branchController.text = storedStudentMap['branch']?.toString() ?? '';
        yearController.text = storedStudentMap['year']?.toString() ?? '';
        sectionController.text = storedStudentMap['section']?.toString() ?? '';
        profilePicUrl =
            storedStudentMap['profilePicUrl']?.toString() ??
            storedStudentMap['photoUrl']?.toString() ??
            storedStudentMap['avatarUrl']?.toString();
        final createdAt = storedStudentMap['createdAt']?.toString() ?? '';
        if (createdAt.isNotEmpty) {
          try {
            final dt = DateTime.parse(createdAt);
            joinedDate = '${dt.day}-${dt.month}-${dt.year}';
          } catch (_) {
            joinedDate = createdAt;
          }
        }
      }

      // placeholder stats
      classesCount = 0;
      attendancePercentage = 0.0;
    } catch (e) {
      debugPrint('Error loading student from storage: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _populateFromUserMap(Map<String, dynamic> user) {
    try {
      final firstName =
          (user['firstName'] ?? user['name']?.split(' ')?.first ?? '')
              .toString();
      final lastName = (user['lastName'] ?? '').toString();
      final fullName = (firstName + ' ' + lastName).trim();

      nameController.text = fullName;
      emailController.text =
          (user['emailId'] ?? user['email'] ?? '').toString();
      phoneController.text = (user['phone'] ?? '').toString();
      rollController.text = (user['rollNo'] ?? '').toString();
      semesterController.text = (user['semester'] ?? '').toString();
      branchController.text = (user['branch'] ?? '').toString();
      yearController.text = (user['year'] ?? '').toString();
      sectionController.text = (user['section'] ?? '').toString();
      profilePicUrl = (user['profilePicUrl'] ?? '').toString();

      final createdAt =
          (user['createdAt'] ?? user['created_at'] ?? '').toString();
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
        box.write('student', user);
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
      'rollNo': rollController.text.trim(),
      if (profilePicUrl != null && profilePicUrl!.trim().isNotEmpty)
        'profilePicUrl': profilePicUrl,
      if (semesterController.text.trim().isNotEmpty)
        'semester': semesterController.text.trim(),
      if (branchController.text.trim().isNotEmpty)
        'branch': branchController.text.trim(),
      if (yearController.text.trim().isNotEmpty)
        'year': yearController.text.trim(),
      if (sectionController.text.trim().isNotEmpty)
        'section': sectionController.text.trim(),
    };

    final fullName = nameController.text.trim();
    if (fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      payload['firstName'] = parts.first;
      if (parts.length > 1) payload['lastName'] = parts.sublist(1).join(' ');
    }

    // If there is no token, persist locally and update UI only
    if (token == null || token.isEmpty) {
      final stored = box.read('student');
      final current =
          (stored is Map<String, dynamic>)
              ? Map<String, dynamic>.from(stored)
              : <String, dynamic>{};
      current.addAll(payload);
      try {
        box.write('student', current);
      } catch (_) {}
      _populateFromUserMap(current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated locally (no token)')),
      );
      return;
    }

    setState(() => isLoading = true);
    final repo = RepositoryProvider.of<AuthRepository>(context);
    try {
      // If there is a pending picked image, upload it first
      if (_pendingPickedImage != null) {
        final file = _pendingPickedImage!;
        final uploaded = await repo.uploadProfilePic(file);
        try {
          final Map<String, dynamic> uploadedMap = Map<String, dynamic>.from(
            uploaded,
          );
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
      final result = await repo.patchProfile(payload);
      // repository.patchProfile returns a Map<String,dynamic> on success
      final Map<String, dynamic> updated = Map<String, dynamic>.from(result);

      // Update UI and storage
      try {
        _populateFromUserMap(updated);
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Notify student_pending_class to refresh internal state
      try {
        context.read<AuthBloc>().add(FetchProfileRequested());
      } catch (_) {}
    } catch (e, st) {
      debugPrint('saveChanges -> patchProfile failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
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
                      // header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
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
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),

                      // content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // profile image with upload button
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF06B6D4),
                                            Color(0xFF2563EB),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0x4D06B6D4),
                                            blurRadius: 20,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 58,
                                        backgroundColor: Colors.white,
                                        child: CircleAvatar(
                                          radius: 55,
                                          backgroundColor: const Color(
                                            0xFF06B6D4,
                                          ),
                                          backgroundImage: _validNetworkImage(),
                                          child:
                                              _validNetworkImage() == null
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
                                          setModalState(
                                            () => isUploading = true,
                                          );
                                          try {
                                            final XFile? picked = await _picker
                                                .pickImage(
                                                  source: ImageSource.gallery,
                                                  imageQuality: 80,
                                                );
                                            if (picked == null) {
                                              setModalState(
                                                () => isUploading = false,
                                              );
                                              return;
                                            }

                                            final file = File(picked.path);
                                            final repo = RepositoryProvider.of<
                                              AuthRepository
                                            >(context);

                                            // upload the image immediately
                                            final uploaded = await repo
                                                .uploadProfilePic(file);

                                            try {
                                              final Map<String, dynamic>
                                              uploadedMap =
                                                  Map<String, dynamic>.from(
                                                    uploaded,
                                                  );
                                              if (uploadedMap['profilePicUrl'] !=
                                                  null) {
                                                profilePicUrl =
                                                    uploadedMap['profilePicUrl']
                                                        .toString();
                                              } else if (uploadedMap['photoUrl'] !=
                                                  null) {
                                                profilePicUrl =
                                                    uploadedMap['photoUrl']
                                                        .toString();
                                              }
                                              _populateFromUserMap(uploadedMap);
                                              // Refresh bloc's internal state
                                              context.read<AuthBloc>().add(
                                                FetchProfileRequested(),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Profile picture updated',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } catch (e) {
                                              debugPrint(
                                                'upload result handling error: $e',
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Upload completed',
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            debugPrint('upload error: $e');
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Upload failed: $e',
                                                ),
                                              ),
                                            );
                                          } finally {
                                            setModalState(
                                              () => isUploading = false,
                                            );
                                            setState(() {});
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF06B6D4),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                          ),
                                          child:
                                              isUploading
                                                  ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                  : const Icon(
                                                    Icons.camera_alt,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              _buildModalTextField(
                                'Full Name',
                                nameController,
                                Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                              _buildModalTextField(
                                'Email',
                                emailController,
                                Icons.email_outlined,
                                enabled: false,
                              ),
                              const SizedBox(height: 16),
                              _buildModalTextField(
                                'Phone Number',
                                phoneController,
                                Icons.phone_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildModalTextField(
                                'Roll Number',
                                rollController,
                                Icons.badge_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildModalTextField(
                                'Semester',
                                semesterController,
                                Icons.school_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildModalTextField(
                                'Branch',
                                branchController,
                                Icons.account_tree_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildModalTextField(
                                'Year',
                                yearController,
                                Icons.calendar_today_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildModalTextField(
                                'Section',
                                sectionController,
                                Icons.group_outlined,
                              ),
                              const SizedBox(height: 32),

                              // save
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF06B6D4),
                                      Color(0xFF2563EB),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0x6606B6D4),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.save_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
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

  Widget _buildModalTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
  }) {
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
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECFEFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header region
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
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
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Card
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
                            color: const Color(0x14000000),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // profile image
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
                                  color: const Color(0x4D06B6D4),
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
                                child:
                                    _validNetworkImage() == null
                                        ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nameController.text.isNotEmpty
                                ? nameController.text
                                : 'Student Name',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            rollController.text.isNotEmpty
                                ? 'Roll No: ${rollController.text}'
                                : 'Roll Number',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (semesterController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF06B6D4),
                                    Color(0xFF2563EB),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Semester ${semesterController.text}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
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
                                  color: const Color(0x4D06B6D4),
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
                                    Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
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

                    // stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: BlocBuilder<StudentClassBloc, StudentClassState>(
                              builder: (context, state) {
                                int classCount = 0;

                                if (state is StudentClassLoaded) {
                                  classCount = state.classes.length;
                                }
                                return _buildStatCard(
                                  icon: Icons.class_outlined,
                                  value: classCount.toString(),
                                  label: 'Classes',
                                  color: const Color(0xFF10B981),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.check_circle_outline,
                              value:
                                  '${attendancePercentage.toStringAsFixed(0)}%',
                              label: 'Attendance',
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.calendar_today_outlined,
                              value:
                                  semesterController.text.isNotEmpty
                                      ? semesterController.text
                                      : '-',
                              label: 'Semester',
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // personal card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0D000000),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.email_outlined,
                            'Email',
                            emailController.text,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Phone',
                            phoneController.text.isNotEmpty
                                ? phoneController.text
                                : 'Not provided',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.account_tree_outlined,
                            'Branch',
                            branchController.text.isNotEmpty
                                ? branchController.text
                                : 'Not provided',
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.calendar_today_outlined,
                            'Joined',
                            joinedDate ?? 'Not available',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // academic card
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0D000000),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAcademicInfoRow(
                            'Roll Number',
                            rollController.text.isNotEmpty
                                ? rollController.text
                                : 'Not provided',
                          ),
                          const SizedBox(height: 16),
                          _buildAcademicInfoRow(
                            'Semester',
                            semesterController.text.isNotEmpty
                                ? semesterController.text
                                : 'Not provided',
                          ),
                          const SizedBox(height: 16),
                          _buildAcademicInfoRow(
                            'Year',
                            yearController.text.isNotEmpty
                                ? yearController.text
                                : 'Not provided',
                          ),
                          const SizedBox(height: 16),
                          _buildAcademicInfoRow(
                            'Section',
                            sectionController.text.isNotEmpty
                                ? sectionController.text
                                : 'Not provided',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // performance
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x0D000000),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPerformanceCard(
                              icon: Icons.star_outline,
                              title: 'Good Standing',
                              subtitle: 'Academic Status',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPerformanceCard(
                              icon: Icons.trending_up_outlined,
                              title: 'Active',
                              subtitle: 'Participation',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000),
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
              color: color.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
            color: const Color(0x1A10B981),
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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

  Widget _buildAcademicInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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

  Widget _buildPerformanceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33F59E0B), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x33F59E0B),
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
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
