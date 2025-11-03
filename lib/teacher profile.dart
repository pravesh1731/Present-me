import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:present_me_flutter/button.dart';
import 'package:present_me_flutter/teacher%20login%20screen.dart';


import 'cloudinary_service.dart';

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
  final mobileController = TextEditingController();
  final hotspotController = TextEditingController();
  final designationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTeacherData();
  }

  Future<void> fetchTeacherData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection("teachers").doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      mobileController.text = data['phone'] ?? '';
      hotspotController.text = data['hotspot'] ?? '';
      designationController.text = data['designation'] ?? '';
      photoUrl = data['photoUrl'];
    }

    setState(() => isLoading = false);
  }

  Future<void> saveChanges() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection("teachers").doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    Map<String, dynamic> updates = {};

    if (nameController.text != data['name']) {
      updates['name'] = nameController.text;
    }
    if (emailController.text != data['email']) {
      updates['email'] = emailController.text;
    }
    if (mobileController.text != data['phone']) {
      updates['phone'] = mobileController.text;
    }
    if (hotspotController.text != data['hotspot']) {
      updates['hotspot'] = hotspotController.text;
    }
    if (designationController.text != data['designation']) {
      updates['designation'] = designationController.text;
    }
    if ((photoUrl ?? '') != (data['photoUrl'] ?? '')) {
      updates['photoUrl'] = photoUrl ?? '';
    }

    if (updates.isNotEmpty) {
      await docRef.update(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No changes to save")),
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
        const SnackBar(content: Text("Image uploaded successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));

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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: isEditing ? pickAndUploadImage : null,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null
                        ? Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                ),

                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => setState(() => isEditing = !isEditing),
                  child: Text(isEditing ? 'Cancel Edit' : 'Edit Profile'),
                ),
              ],
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
                    buildTextField("Email", emailController),
                    buildTextField("Mobile", mobileController),
                    buildTextField("Hotspot Name", hotspotController),
                    buildTextField("Designation", designationController),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: Button(text: 'Save Changes', onPressed: saveChanges),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => teacherLogin()),
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

  Widget buildTextField(String label, TextEditingController controller) {
    final isEmailField = label.toLowerCase() == "email";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: isEditing && !isEmailField,  // email is non-editable
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: (isEditing && !isEmailField)
              ? Colors.white
              : Colors.grey.shade200,
        ),
      ),
    );
  }
}
