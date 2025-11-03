import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:present_me_flutter/teacher%20login%20screen.dart';

import 'auth_service.dart';
import 'teacher_model.dart';
import 'button.dart';

class TeacherSignup extends StatefulWidget {
  @override
  State<TeacherSignup> createState() => _TeacherSignupState();
}

class _TeacherSignupState extends State<TeacherSignup> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final hotspotController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  Future<void> createUser() async {
    if (_formKey.currentState!.validate()) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Passwords do not match")),
        );
        return;
      }

      try {
        final user = await _authService.signUp(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        if (user != null) {
          final teacher = Teacher(
            uid: user.uid,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            hotspot: hotspotController.text.trim(),
            createdAt: DateTime.now(),
          );

          await FirebaseFirestore.instance
              .collection('teachers')
              .doc(user.uid)
              .set(teacher.toMap());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration successful!")),
          );
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) => teacherLogin(),
              transitionsBuilder: (_, animation, __, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutBack;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );

          // Optionally clear the form fields
          _formKey.currentState!.reset();
          nameController.clear();
          emailController.clear();
          phoneController.clear();
          hotspotController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign up failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff0BCCEB), Color(0xff0A80F5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 90),
                Logo(),
                const Text(
                  'Present-Me',
                  style: TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                    elevation: 32,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Teacher Sign Up", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: nameController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.account_circle_outlined),
                                hintText: "Enter your full name",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (value) => value!.isEmpty ? 'Enter name' : null,
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: "Enter your email",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (value) => value!.isEmpty ? 'Enter email' : null,
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: hotspotController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.cell_tower_outlined),
                                hintText: "Enter your hotspot name",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.call),
                                hintText: "Enter your mobile number",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline),
                                hintText: "Enter your password",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (value) => value!.length < 6 ? 'Minimum 6 characters' : null,
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline),
                                hintText: "Confirm password",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              validator: (value) => value!.isEmpty ? 'Confirm your password' : null,
                            ),

                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Button(text: 'Sign Up', onPressed: createUser),
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
      ),
    );
  }
}
