import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:present_me_flutter/core/widgets/header.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey                = GlobalKey<FormState>();
  final _currentPasswordCtrl    = TextEditingController();
  final _newPasswordCtrl        = TextEditingController();
  final _confirmPasswordCtrl    = TextEditingController();
  final GetStorage _storage     = GetStorage();

  bool _showCurrent  = false;
  bool _showNew      = false;
  bool _showConfirm  = false;
  bool _isLoading    = false;
  bool _isSuccess    = false;

  // inline error from API (e.g. wrong current password)
  String? _apiError;

  late AnimationController _successAnim;
  late Animation<double>   _scaleAnim;

  static const _baseUrl = 'https://presentme.in/api';

  String _getToken() => _storage.read('token')?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _successAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════
  //  API CALL
  // ═══════════════════════════════════════════════════════

  Future<void> _handleSubmit() async {
    // clear previous API error
    setState(() => _apiError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/students/change-password'),
        headers: {
          'Authorization': 'Bearer ${_getToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'oldPassword': _currentPasswordCtrl.text.trim(),
          'newPassword': _newPasswordCtrl.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Success
        setState(() => _isSuccess = true);
        _successAnim.forward();
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      } else {
        // ❌ API error (wrong password etc.)
        setState(() => _apiError = data['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      setState(() => _apiError = 'Network error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(child: Header(heading: "Change Password", subheading: "Keep your account secure")),
          // ── Body ──
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: _isSuccess ? _buildSuccessCard() : _buildFormCard(),
            ),
          ),
        ],
      ),
    );
  }


  // ── Form card ──
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── API error banner ──
            if (_apiError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _apiError!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Current password ──
            _fieldLabel('Current Password'),
            const SizedBox(height: 8),
            _passwordField(
              controller:  _currentPasswordCtrl,
              hint:        'Enter current password',
              showPassword: _showCurrent,
              onToggle:    () => setState(() => _showCurrent = !_showCurrent),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your current password';
                return null;
              },
            ),
            const SizedBox(height: 20),



            // ── New password ──
            _fieldLabel('New Password'),
            const SizedBox(height: 8),
            _passwordField(
              controller:   _newPasswordCtrl,
              hint:         'Enter new password',
              showPassword: _showNew,
              onToggle:     () => setState(() => _showNew = !_showNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a new password';
                if (v.length < 6) return 'Password must be at least 6 characters';
                if (v == _currentPasswordCtrl.text.trim()) {
                  return 'New password must differ from current password';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Confirm password ──
            _fieldLabel('Re-enter New Password'),
            const SizedBox(height: 8),
            _passwordField(
              controller:   _confirmPasswordCtrl,
              hint:         'Confirm new password',
              showPassword: _showConfirm,
              onToggle:     () => setState(() => _showConfirm = !_showConfirm),
              // ✅ UI validation — passwords must match
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your new password';
                if (v != _newPasswordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Submit button ──
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : [const Color(0xFF06B6D4), const Color(0xFF2563EB)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_isLoading ? Colors.grey : const Color(0xFF2563EB)).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isLoading ? null : _handleSubmit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _isLoading
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                        SizedBox(width: 12),
                        Text('Updating...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_reset_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Password tips ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tips_and_updates_outlined, size: 14, color: Color(0xFF3B4FE0)),
                      SizedBox(width: 6),
                      Text('Password Tips', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3B4FE0))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _tip('At least 8 characters long'),
                  _tip('Mix letters, numbers & symbols'),
                  _tip('Avoid using your name or birthdate'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success card ──
  Widget _buildSuccessCard() {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            // animated check circle
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Password Updated!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your password has been changed successfully.\nYou can now login with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black45, height: 1.5),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSuccess = false;
                  _successAnim.reset();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF3B4FE0).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Text(
                  'Change Again',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
  );

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF3B4FE0), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      ],
    ),
  );

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller:     controller,
      obscureText:    !showPassword,
      validator:      validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled:    true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B4FE0), width: 1.5)),
        errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.black38, size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}