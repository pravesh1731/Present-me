import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import '../../core/constants/constants.dart';

class TeacherNoticePage extends StatefulWidget {
  final String classCode;
  final String className;

  const TeacherNoticePage({
    Key? key,
    required this.classCode,
    required this.className,
  }) : super(key: key);

  @override
  _TeacherNoticePageState createState() => _TeacherNoticePageState();
}

class _TeacherNoticePageState extends State<TeacherNoticePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _priority = 'normal';
  bool _isSending = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notices = [];

  // Edit mode state
  bool _isEditMode = false;
  String? _editingNoticeId;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final token = getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/teachers/notices/${widget.classCode}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _notices =
          List<Map<String, dynamic>>.from(data['notices'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Fetch notices error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Send new notice ──────────────────────────────────────────────
  Future<void> _sendNotice() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      _showSnackBar('Please fill title and message');
      return;
    }

    setState(() => _isSending = true);

    try {
      final token = getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/teachers/send-notice'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'classCode': widget.classCode,
          'className': widget.className,
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'priority': _priority,
        }),
      );

      if (res.statusCode == 200) {
        _clearForm();
        Navigator.pop(context);
        _showSnackBar('Notice sent successfully ✓');
        await _fetchNotices();
      } else {
        final data = jsonDecode(res.body);
        _showSnackBar(data['message'] ?? 'Failed to send notice');
      }
    } catch (e) {
      _showSnackBar('Network error. Try again.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ─── Update existing notice ───────────────────────────────────────
  Future<void> _updateNotice() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      _showSnackBar('Please fill title and message');
      return;
    }

    setState(() => _isSending = true);

    try {
      final token = getToken();
      final res = await http.patch(
        Uri.parse('$baseUrl/teachers/notice/$_editingNoticeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'classCode': widget.classCode,
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'priority': _priority,
        }),
      );

      if (res.statusCode == 200) {
        _clearForm();
        Navigator.pop(context);
        _showSnackBar('Notice updated successfully ✓');
        await _fetchNotices();
      } else {
        final data = jsonDecode(res.body);
        _showSnackBar(data['message'] ?? 'Failed to update notice');
      }
    } catch (e) {
      _showSnackBar('Network error. Try again.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  // ─── Delete notice ────────────────────────────────────────────────
  Future<void> _deleteNotice(String noticeId) async {
    try {
      final token = getToken();
      final res = await http.delete(
        Uri.parse(
            '$baseUrl/teachers/notice/$noticeId?classCode=${widget.classCode}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _showSnackBar('Notice deleted');
        await _fetchNotices();
      }
    } catch (e) {
      _showSnackBar('Failed to delete notice');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _priority = 'normal';
      _isEditMode = false;
      _editingNoticeId = null;
    });
  }

  // ─── Open bottom sheet for new notice ────────────────────────────
  void _showSendNoticeSheet() {
    _clearForm();
    _openNoticeSheet();
  }

  // ─── Open bottom sheet for edit notice ───────────────────────────
  void _showEditNoticeSheet(Map<String, dynamic> notice) {
    setState(() {
      _isEditMode = true;
      _editingNoticeId = notice['noticeId'];
      _titleController.text = notice['title'] ?? '';
      _messageController.text = notice['message'] ?? '';
      _priority = notice['priority'] ?? 'normal';
    });
    _openNoticeSheet();
  }

  void _openNoticeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title row
              Row(
                children: [
                  Text(
                    _isEditMode ? 'Edit Notice' : 'Send Notice',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_isEditMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Editing',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Title field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Notice Title',
                  hintText: 'e.g. Assignment Due Tomorrow',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF00A76F), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Message field
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'Write your notice here...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF00A76F), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Priority
              const Text(
                'Priority',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _priorityChip('normal', '📢 Normal', Colors.blue,
                      setSheetState),
                  const SizedBox(width: 8),
                  _priorityChip('important', '⚠️ Important',
                      Colors.orange, setSheetState),
                  const SizedBox(width: 8),
                  _priorityChip('urgent', '🔴 Urgent', Colors.red,
                      setSheetState),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons
              if (_isEditMode)
                Row(
                  children: [
                    // Cancel edit
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save edit
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _updateNotice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSending
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Save Changes',
                            style: TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
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
                    onPressed: _isSending ? null : _sendNotice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A76F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Send Notice',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => _clearForm());
  }

  Widget _priorityChip(String value, String label, Color color,
      StateSetter setSheetState) {
    final selected = _priority == value;
    return GestureDetector(
      onTap: () {
        setSheetState(() => _priority = value);
        setState(() => _priority = value);
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : Colors.grey.shade600,
          ),
        ),
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
        return Colors.blue;
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF7),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendNoticeSheet,
        backgroundColor: const Color(0xFF00A76F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Notice',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Header(heading: 'Notices', subheading: widget.className),
          Expanded(
            child: _isLoading
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF00A76F)))
                : _notices.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('No notices yet',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Tap + New Notice to send one',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13)),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchNotices,
              color: const Color(0xFF00A76F),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16, 12, 16, 100),
                itemCount: _notices.length,
                itemBuilder: (context, index) {
                  final notice = _notices[index];
                  final priority =
                      notice['priority'] ?? 'normal';
                  final color = _getPriorityColor(priority);

                  return Dismissible(
                    key: Key(notice['noticeId']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding:
                      const EdgeInsets.only(right: 20),
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete,
                          color: Colors.red),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title:
                          const Text('Delete Notice'),
                          content: const Text(
                              'Are you sure you want to delete this notice?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(
                                  context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(
                                  context, true),
                              child: const Text('Delete',
                                  style: TextStyle(
                                      color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) =>
                        _deleteNotice(notice['noticeId']),
                    child: Container(
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(
                              color: color, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color: color
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(
                                      20),
                                  border: Border.all(
                                      color: color
                                          .withOpacity(0.3)),
                                ),
                                child: Text(
                                  priority.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                    FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // ← Edit button
                              GestureDetector(
                                onTap: () =>
                                    _showEditNoticeSheet(
                                        notice),
                                child: Container(
                                  padding:
                                  const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange
                                        .withOpacity(0.1),
                                    borderRadius:
                                    BorderRadius.circular(
                                        8),
                                  ),
                                  child: const Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: Colors.orange),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(
                                    notice['createdAt'] ??
                                        ''),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notice['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notice['message'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // Show "edited" tag if updatedAt != createdAt
                          if (notice['updatedAt'] != null &&
                              notice['updatedAt'] !=
                                  notice['createdAt']) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Edited · ${_formatDate(notice['updatedAt'])}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}