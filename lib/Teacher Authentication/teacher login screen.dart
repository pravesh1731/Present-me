import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/src/bloc/teacher_auth/teacher_auth_bloc.dart' hide TeacherPendingVerification;
import 'package:present_me_flutter/Teacher%20Authentication/teacher_pending_verification.dart' as pending_widget;

import '../Teacher Forget Password Screen/teacherForgetPassword.dart';
import '../Teacher Screens/teacher home screen.dart';
import 'teacher sign up.dart';

class teacherLogin extends StatefulWidget {
  @override
  State<teacherLogin> createState() => _teacherLoginState();
}

class _teacherLoginState extends State<teacherLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidEmail(String email) {
    // Simple and reliable email validation: enough for client-side checks.
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailPattern.hasMatch(email.trim());
  }


  // Use the BuildContext coming from the widget subtree (e.g. the BlocBuilder's context)
  Future<void> _loginWithContext(BuildContext ctx) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all the fields.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar("Please enter a valid email address.");
      return;
    }

    try {
      // Dispatch login event to AuthBloc using the provided context (from BlocBuilder)
      ctx.read<TeacherAuthBloc>().add(
        TeacherLoginRequested(email: email, password: password),
      );
    } catch (e) {
      _showSnackBar('Internal error: unable to access authentication provider.');
    }
  }

  // Helper: Normalize teacher payload into a map and decide routing
  Future<void> _navigateAfterAuth(BuildContext context, dynamic teacher) async {
    Map<String, dynamic> teacherMap = {};
    try {
      if (teacher is Map) {
        teacherMap = Map<String, dynamic>.from(teacher);
      } else if (teacher is String) {
        try {
          final decoded = jsonDecode(teacher);
          if (decoded is Map) teacherMap = Map<String, dynamic>.from(decoded);
        } catch (_) {
          // ignore
        }
      }
    } catch (_) {
      // ignore parsing errors
    }

    // Fallback email
    final email = (teacherMap['emailId'] ?? teacherMap['email'] ?? _emailController.text).toString();

    // Determine status fields that servers commonly use
    final statusCandidates = [
      teacherMap['status']
    ];

    String statusLower = '';
    for (final s in statusCandidates) {
      if (s != null) {
        statusLower = s.toString().toLowerCase();
        break;
      }
    }

    // Some APIs return boolean flags
    final verifiedFlag = (teacherMap['verified'] is bool) ? teacherMap['verified'] as bool : null;
    final isVerifiedFlag = (teacherMap['isVerified'] is bool) ? teacherMap['isVerified'] as bool : null;

    final bool isPending = (
      statusLower == 'pending' ||
      (verifiedFlag != null && verifiedFlag == false) ||
      (isVerifiedFlag != null && isVerifiedFlag == false)
    );

    if (isPending) {
      // Clear persisted session so app restart won't auto-open teacherHome
      try {
        final box = GetStorage();
        await box.remove('token');
        await box.remove('teacher');
        await box.remove('role');
      } catch (_) {}
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => pending_widget.TeacherPendingVerification()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => teacherHome(),
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
    }
  }

  Widget _buildBody() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFECFDF5), // emerald-50
              Color(0xFFF0FDFA), // teal-50
              Color(0xFFECFEFF), // cyan-50
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon + Titles
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.10),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.groups_outlined,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Teacher Login",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Welcome back! Sign in to continue",
                          style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w400),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Card container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 32, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Email
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Email Address", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: "teacher@example.com",
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Password
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Password", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: "Enter your password",
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey.shade400),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200, width: 1)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false), activeColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("Remember me", style: TextStyle(fontSize: 14, color: Colors.black54)),
                                  ],
                                ),

                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        transitionDuration: const Duration(milliseconds: 600),
                                        pageBuilder: (_, __, ___) => ForgetPassword(),
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
                                  },
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w500, fontSize: 14)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: BlocBuilder<TeacherAuthBloc, TeacherAuthState>(
                                builder: (context, state) {
                                  final loading = state is TeacherAuthLoading;
                                  if (loading) {
                                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                                  }

                                  return ElevatedButton(
                                    onPressed: () => _loginWithContext(context),
                                    style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                                    child: Ink(
                                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.all(Radius.circular(14))),
                                      child: Container(alignment: Alignment.center, height: 48, child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 40),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(color: Colors.black54, fontSize: 14)),
                                GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherSignup())), child: const Text("Sign up", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 14))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Text('© 2025 Present-Me. All rights reserved.', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TeacherAuthBloc, TeacherAuthState>(
      listener: (context, state) {
        if (state is TeacherAuthAuthenticated) {
          // decide route based on teacher profile
          _navigateAfterAuth(context, state.teacher);
        } else if (state is TeacherAuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        body: _buildBody(),
      ),
    );
  }
}
