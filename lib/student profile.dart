import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:present_me_flutter/student%20login%20screen.dart';
import 'button.dart';
import 'cloudinary_service.dart'; // Make sure this exists

class student_Profile extends StatefulWidget {
  @override
  State<student_Profile> createState() => _student_ProfileState();
}

class _student_ProfileState extends State<student_Profile> {
  bool isEditing = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final hotspotController = TextEditingController();
  final designationController = TextEditingController();

  String? imageUrl;
  String? publicId;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final studentDoc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          mobileController.text = data['phone'] ?? '';
          hotspotController.text = data['roll'] ?? '';
          designationController.text = data['semester'] ?? '';
          imageUrl = data['photoUrl'];
          publicId = data['public_id'];
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('students').doc(user.uid).update({
        'name': nameController.text,
        'phone': mobileController.text,
        'roll': hotspotController.text,
        'semester': designationController.text,
        'photoUrl': imageUrl,
        'public_id': publicId,
      });

      setState(() => isEditing = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile == null) return;

    final File file = File(pickedFile.path);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uploadResult = await CloudinaryHelper.uploadImage(file);
      if (uploadResult != null) {
        if (publicId != null && publicId!.isNotEmpty) {
          await CloudinaryHelper.deleteImage(publicId!);
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('students').doc(user.uid).update({
            'photoUrl': uploadResult['url'],
            'public_id': uploadResult['public_id'],
          });
        }

        setState(() {
          imageUrl = uploadResult['url'];
          publicId = uploadResult['public_id'];
        });

        Navigator.of(context).pop(); // Close progress dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(fontSize: 24, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          GestureDetector(
            onTap: isEditing ? _pickAndUploadImage : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
                    child: imageUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => isEditing = !isEditing),
                    child: Text(isEditing ? 'Cancel Edit' : 'Edit Profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    buildTextField("Name", nameController),
                    buildTextField("Email", emailController, isEditable: false),
                    buildTextField("Mobile", mobileController),
                    buildTextField("Roll No", hotspotController, isEditable: false),
                    buildTextField("Semester", designationController),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: Button(text: 'Save Changes', onPressed: _saveChanges),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => studentlogin()),
                                (route) => false,
                          );
                        },
                        child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: isEditable && isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: isEditing && isEditable ? Colors.white : Colors.grey.shade200,
        ),
      ),
    );
  }
}
