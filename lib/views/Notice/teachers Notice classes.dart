import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import 'package:present_me_flutter/viewmodels/teacher_class/teacher_class_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/constants.dart';
import '../../../../viewmodels/teacher_auth/teacher_auth_bloc.dart';
import 'Teacher Notice main.dart';

class TeacherNoticeClass extends StatefulWidget {
  const TeacherNoticeClass({super.key});

  @override
  State<TeacherNoticeClass> createState() => _TeacherNoticeClassState();
}

class _TeacherNoticeClassState extends State<TeacherNoticeClass>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _generalNotices = [];
  bool _isGeneralLoading = true;
  Map<String, int> _noticeCounts = {};
  String? _myTeacherId;

  bool _isEditMode = false;
  String? _editingNoticeId;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  String _priority = 'normal';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeacherId();
      _fetchClasses();
      _fetchGeneralNotices();
    });
  }

  // ─── Load teacher ID ──────────────────────────────────────────────
  void _loadTeacherId() {
    // Try bloc first
    final authState = context.read<TeacherAuthBloc>().state;
    debugPrint('Auth state: ${authState.runtimeType}');

    if (authState is TeacherAuthAuthenticated) {
      final id = authState.teacher['teacherId'] as String?;
      if (id != null && id.isNotEmpty) {
        setState(() => _myTeacherId = id);
        debugPrint('✅ Teacher ID from bloc: $_myTeacherId');
        return;
      }
    }

    // Fallback: decode JWT token
    debugPrint('⚠️ Bloc not ready, decoding token...');
    _loadTeacherIdFromToken();
  }

  void _loadTeacherIdFromToken() {
    try {
      final token = getToken();
      if (token.isEmpty) return;

      final parts = token.split('.');
      if (parts.length != 3) return;

      // Decode base64url payload
      String payload = parts[1];
      // Add padding
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final decoded = utf8.decode(base64.decode(payload));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      debugPrint('JWT payload: $data');

      // Try common key names
      final id = data['id'] as String? ??
          data['teacherId'] as String? ??
          data['userId'] as String?;

      if (id != null && mounted) {
        setState(() => _myTeacherId = id);
        debugPrint('✅ Teacher ID from token: $_myTeacherId');
      }
    } catch (e) {
      debugPrint('Token decode error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _fetchClasses() {
    try {
      final token = getToken();
      if (token.isNotEmpty) {
        context.read<TeacherClassBloc>().add(TeacherFetchClasses(token));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchGeneralNotices() async {
    setState(() => _isGeneralLoading = true);
    try {
      final token = getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/teachers/general-notices'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('General notices: ${res.statusCode} ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _generalNotices =
          List<Map<String, dynamic>>.from(data['notices'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('General notices error: $e');
    } finally {
      if (mounted) setState(() => _isGeneralLoading = false);
    }
  }

  Future<void> _fetchNoticeCounts(List classes) async {
    try {
      final token = getToken();
      await Future.wait(
        classes.map((cls) async {
          final res = await http.get(
            Uri.parse('$baseUrl/teachers/notices/${cls.classCode}'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (mounted) {
              setState(() {
                _noticeCounts[cls.classCode] =
                    (data['count'] as num?)?.toInt() ?? 0;
              });
            }
          }
        }),
      );
    } catch (e) {
      debugPrint('Notice counts error: $e');
    }
  }

  Future<void> _sendGeneralNotice() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _messageCtrl.text.trim().isEmpty) {
      _showSnackBar('Please fill title and message');
      return;
    }
    if (mounted) setState(() => _isSending = true);
    try {
      final token = getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/admin/send-general-notice'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _titleCtrl.text.trim(),
          'message': _messageCtrl.text.trim(),
          'priority': _priority,
        }),
      );
      if (res.statusCode == 200) {
        _clearForm();
        if (mounted) Navigator.pop(context);
        _showSnackBar('Notice sent to all ✓');
        await _fetchGeneralNotices();
      } else {
        final data = jsonDecode(res.body);
        _showSnackBar(data['message'] ?? 'Failed to send');
      }
    } catch (e) {
      _showSnackBar('Network error. Try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _updateGeneralNotice() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _messageCtrl.text.trim().isEmpty) {
      _showSnackBar('Please fill title and message');
      return;
    }
    if (mounted) setState(() => _isSending = true);
    try {
      final token = getToken();
      final res = await http.patch(
        Uri.parse(
            '$baseUrl/teachers/general-notice/$_editingNoticeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _titleCtrl.text.trim(),
          'message': _messageCtrl.text.trim(),
          'priority': _priority,
        }),
      );
      if (res.statusCode == 200) {
        _clearForm();
        if (mounted) Navigator.pop(context);
        _showSnackBar('Notice updated ✓');
        await _fetchGeneralNotices();
      } else {
        final data = jsonDecode(res.body);
        _showSnackBar(data['message'] ?? 'Failed to update');
      }
    } catch (e) {
      _showSnackBar('Network error. Try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteGeneralNotice(String noticeId) async {
    try {
      final token = getToken();
      final res = await http.delete(
        Uri.parse('$baseUrl/teachers/general-notice/$noticeId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _showSnackBar('Notice deleted');
        await _fetchGeneralNotices();
      } else {
        final data = jsonDecode(res.body);
        _showSnackBar(data['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      _showSnackBar('Network error');
    }
  }

  void _clearForm() {
    _titleCtrl.clear();
    _messageCtrl.clear();
    if (mounted) {
      setState(() {
        _priority = 'normal';
        _isEditMode = false;
        _editingNoticeId = null;
      });
    }
  }

  // ─── Long press sheet ─────────────────────────────────────────────
  void _showSheet(
      Map<String, dynamic> notice, Color color, String priority) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Notice preview
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withOpacity(0.25)),
                    ),
                    child: Text(priority.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      notice['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Edit
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.orange, size: 18),
              ),
              title: const Text('Edit Notice',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: Text('Update title, message or priority',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              onTap: () {
                Navigator.pop(context);
                _showEditSheet(notice);
              },
            ),

            // Delete
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 18),
              ),
              title: const Text('Delete Notice',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.red)),
              subtitle: Text('This cannot be undone',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Notice'),
                    content: const Text(
                        'Are you sure you want to delete this notice?'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  _deleteGeneralNotice(notice['noticeId']);
                }
              },
            ),

            // Cancel
            ListTile(
              leading: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.close,
                    color: Colors.grey.shade600, size: 18),
              ),
              title: Text('Cancel',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSendSheet() {
    _clearForm();
    _openSheet();
  }

  void _showEditSheet(Map<String, dynamic> notice) {
    setState(() {
      _isEditMode = true;
      _editingNoticeId = notice['noticeId'];
      _titleCtrl.text = notice['title'] ?? '';
      _messageCtrl.text = notice['message'] ?? '';
      _priority = notice['priority'] ?? 'normal';
    });
    _openSheet();
  }

  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _isEditMode
                        ? 'Edit Notice'
                        : 'Send General Notice',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  if (_isEditMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Text('Editing',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Text('Institution-wide',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E40AF))),
                    ),
                ],
              ),
              if (!_isEditMode) ...[
                const SizedBox(height: 4),
                Text(
                  'Visible to all teachers & students',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Notice Title',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF2563EB), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Priority',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _priorityChip('normal', '📢 Normal',
                      Colors.blue, setSheet),
                  const SizedBox(width: 8),
                  _priorityChip('important', '⚠️ Important',
                      Colors.orange, setSheet),
                  const SizedBox(width: 8),
                  _priorityChip('urgent', '🔴 Urgent',
                      Colors.red, setSheet),
                ],
              ),
              const SizedBox(height: 20),
              if (_isEditMode)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            _clearForm();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14)),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: Colors.grey)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSending
                              ? null
                              : _updateGeneralNotice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14)),
                          ),
                          child: _isSending
                              ? const SizedBox(
                              width: 20, height: 20,
                              child:
                              CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                              : const Text('Save Changes',
                              style: TextStyle(
                                  fontWeight:
                                  FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                    _isSending ? null : _sendGeneralNotice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14)),
                    ),
                    child: _isSending
                        ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2))
                        : const Text('Send to All',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).whenComplete(_clearForm);
  }

  Widget _priorityChip(String value, String label, Color color,
      StateSetter setSheet) {
    final selected = _priority == value;
    return GestureDetector(
      onTap: () {
        setSheet(() => _priority = value);
        setState(() => _priority = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? color : Colors.grey.shade600,
            )),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.orange;
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy · hh:mm a').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF7),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox();
          return FloatingActionButton.extended(
            onPressed: _showSendSheet,
            backgroundColor: const Color(0xFF2563EB),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Notice',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          );
        },
      ),
      body: Column(
        children: [
          Header(
              heading: "Notices",
              subheading: "Manage & view notices"),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFE8EDF5)),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF7A8AAA),
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('General Notice'),
                        if (_generalNotices.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Text(
                                '${_generalNotices.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight:
                                    FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Class Notice'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralNoticesTab(),
                _buildClassNoticesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralNoticesTab() {
    if (_isGeneralLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: List.generate(3, (_) => _shimmerNotice()),
      );
    }

    if (_generalNotices.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No general notices',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Tap + New Notice to send one',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchGeneralNotices,
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _generalNotices.length,
        itemBuilder: (context, index) {
          final notice = _generalNotices[index];
          final priority = notice['priority'] ?? 'normal';
          final color = _getPriorityColor(priority);
          final isMyNotice =
              _myTeacherId != null &&
                  notice['senderId'] == _myTeacherId;

          return GestureDetector(
            onTap: () {
              if (!isMyNotice) return;
              _showSheet(notice, color, priority);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                    left: BorderSide(color: color, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withOpacity(0.25)),
                        ),
                        child: Text(priority.toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                      const Spacer(),
                      if (isMyNotice) ...[
                        Icon(Icons.more_vert,
                            size: 16,
                            color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _formatDate(notice['createdAt'] ?? ''),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(notice['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(notice['message'] ?? '',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          notice['senderName'] ?? 'Teacher',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500)),
                      if (isMyNotice) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: const Text('You',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF2563EB),
                                  fontWeight:
                                  FontWeight.w600)),
                        ),
                      ],
                      if (notice['updatedAt'] != null &&
                          notice['updatedAt'] !=
                              notice['createdAt']) ...[
                        const SizedBox(width: 6),
                        Text('· Edited',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassNoticesTab() {
    return BlocBuilder<TeacherClassBloc, TeacherClassState>(
      builder: (context, state) {
        if (state is TeacherClassLoading) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: List.generate(3, (_) => _shimmerCard()),
          );
        }
        if (state is TeacherClassError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message,
                    style: const TextStyle(
                        color: Color(0xFF6B7280))),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchClasses,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is TeacherClassLoaded) {
          if (state.classes.isEmpty) {
            return const Center(
              child: Text('No classes found.',
                  style: TextStyle(color: Color(0xFF6B7280))),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchNoticeCounts(state.classes);
          });
          return RefreshIndicator(
            onRefresh: () async =>
                _fetchNoticeCounts(state.classes),
            color: const Color(0xFF00A76F),
            child: ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.classes.length,
              itemBuilder: (context, index) {
                final cls = state.classes[index];
                final count =
                    _noticeCounts[cls.classCode] ?? 0;
                return _buildClassCard(cls, count);
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildClassCard(dynamic cls, int noticeCount) {
    final Color primary =
    _classColors[(cls.classCode.hashCode) % _classColors.length];
    final Color secondary = _classColors[
    (cls.classCode.hashCode + 1) % _classColors.length];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherNoticePage(
              classCode: cls.classCode,
              className: cls.className,
            ),
          ),
        );
        final s = context.read<TeacherClassBloc>().state;
        if (s is TeacherClassLoaded) {
          _fetchNoticeCounts(s.classes);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(colors: [
                    _soften(primary, 0.28),
                    _soften(secondary, 0.28),
                  ]),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: _tint(primary, 0.9),
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                              color:
                              primary.withOpacity(0.18)),
                        ),
                        child: Icon(Icons.menu_book_outlined,
                            color: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(cls.className,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                    FontWeight.w700,
                                    color: Colors.black87),
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis),
                            Text(
                              '${cls.classCode} · ${cls.students?.length ?? 0} students',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      if (noticeCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(
                                    0xFFBFDBFE)),
                          ),
                          child: Text(
                            '$noticeCount ${noticeCount == 1 ? 'notice' : 'notices'}',
                            style: const TextStyle(
                                color: Color(0xFF1E40AF),
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text(
                          '${cls.startTime} - ${cls.endTime}',
                          style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.room_outlined,
                          size: 14, color: Colors.black38),
                      const SizedBox(width: 4),
                      Text('Room: ${cls.roomNo}',
                          style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildCodeBadge(cls.classCode, primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerNotice() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 100,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _shimmerCard() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 120,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
    ),
  );
}

Color _tint(Color color, double amount) =>
    Color.lerp(color, Colors.white, amount) ?? color;

Color _soften(Color color, double amount) =>
    Color.lerp(color, Colors.white, amount) ?? color;

Widget _buildCodeBadge(String code, Color primary) {
  return Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _tint(primary, 0.92),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: primary.withOpacity(0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.key_rounded, size: 14, color: primary),
        const SizedBox(width: 4),
        Text(code,
            style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

const List<Color> _classColors = [
  Color(0xFF10B981), Color(0xFF059669),
  Color(0xFF6366F1), Color(0xFF4F46E5),
  Color(0xFF8B5CF6), Color(0xFF7C3AED),
  Color(0xFFF59E0B), Color(0xFFD97706),
  Color(0xFFEF4444), Color(0xFFDC2626),
  Color(0xFF14B8A6), Color(0xFF0D9488),
  Color(0xFF06B6D4), Color(0xFF0891B2),
  Color(0xFFA855F7), Color(0xFF9333EA),
  Color(0xFF3B82F6), Color(0xFF2563EB),
  Color(0xFFF97316), Color(0xFFEA580C),
];