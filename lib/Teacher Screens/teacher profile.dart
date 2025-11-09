import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class teacher_Profile extends StatefulWidget {
  @override
  State<teacher_Profile> createState() => _teacher_ProfileState();
}

class _teacher_ProfileState extends State<teacher_Profile> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isEditing = false;
  bool isLoading = true;
  String? photoUrl;

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

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
    fetchClassesAndStudents();
  }

  Future<void> fetchClassesAndStudents() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final classesSnapshot = await _firestore
          .collection('classes')
          .where('createdBy', isEqualTo: user.uid)
          .get();

      int totalStudents = 0;
      for (var doc in classesSnapshot.docs) {
        final students = doc.data()['students'] as List? ?? [];
        totalStudents += students.length;
      }

      setState(() {
        classesCount = classesSnapshot.docs.length;
        studentsCount = totalStudents;
      });
    } catch (e) {
      print('Error fetching classes and students: $e');
      // Keep the default values if error occurs
    }
  }

  Future<void> fetchTeacherData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      final doc = await _firestore.collection("teachers").doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        officeController.text = data['office'] ?? '';
        departmentController.text = data['department'] ?? '';
        specializationController.text = data['specialization'] ?? '';
        qualificationController.text = data['qualification'] ?? '';
        experienceController.text = data['experience'] ?? '';
        employeeIdController.text = data['employeeId'] ?? '';
        photoUrl = data['photoUrl'];
        
        // Format joined date if it exists
        if (data['createdAt'] != null) {
          final timestamp = data['createdAt'] as Timestamp;
          final date = timestamp.toDate();
          final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                          'July', 'August', 'September', 'October', 'November', 'December'];
          joinedDate = '${months[date.month - 1]} ${date.year}';
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error fetching teacher data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> saveChanges() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection("teachers").doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    Map<String, dynamic> updates = {};

    if (nameController.text != data['name']) updates['name'] = nameController.text;
    if (emailController.text != data['email']) updates['email'] = emailController.text;
    if (phoneController.text != data['phone']) updates['phone'] = phoneController.text;
    if (officeController.text != (data['office'] ?? '')) updates['office'] = officeController.text;
    if (departmentController.text != (data['department'] ?? '')) updates['department'] = departmentController.text;
    if (specializationController.text != (data['specialization'] ?? '')) updates['specialization'] = specializationController.text;
    if (qualificationController.text != (data['qualification'] ?? '')) updates['qualification'] = qualificationController.text;
    if (experienceController.text != (data['experience'] ?? '')) updates['experience'] = experienceController.text;
    if (employeeIdController.text != (data['employeeId'] ?? '')) updates['employeeId'] = employeeIdController.text;
    if ((photoUrl ?? '') != (data['photoUrl'] ?? '')) updates['photoUrl'] = photoUrl ?? '';

    if (updates.isNotEmpty) {
      await docRef.update(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Profile updated successfully"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("No changes to save"),
            ],
          ),
          backgroundColor: const Color(0xFF6B7280),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    setState(() => isEditing = false);
  }


  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final user = _auth.currentUser;
    if (user == null) return;

    final teacherDoc = await _firestore.collection("teachers").doc(user.uid).get();
    final existingPhotoId = teacherDoc.data()?['photoId'];

    // Delete old image
    if (existingPhotoId != null) {
      await CloudinaryHelper.deleteImage(existingPhotoId);
    }

    // Upload new image
    final result = await CloudinaryHelper.uploadImage(File(picked.path));

    Navigator.of(context).pop(); // Close loader

    if (result != null) {
      photoUrl = result['url'];
      await _firestore.collection("teachers").doc(user.uid).update({
        'photoUrl': result['url'],
        'photoId': result['public_id'],
      });

      setState(() {}); // Refresh UI

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Image uploaded successfully"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Image upload failed"),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                                  backgroundColor: const Color(0xFF06B6D4),
                                  child: photoUrl == null
                                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  await pickAndUploadImage();
                                  setModalState(() {});
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
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                                  backgroundColor: const Color(0xFF06B6D4),
                                  child: photoUrl == null
                                      ? const Icon(Icons.person, size: 50, color: Colors.white)
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
                              ? '${departmentController.text} Department'
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
                        Row(
                          children: [
                            const Text(
                              'Qualification',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (qualificationController.text.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  qualificationController.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              const Text(
                                'Not provided',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                          ],
                        ),
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
