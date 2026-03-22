import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:present_me_flutter/components/common/Button/token.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import '../../core/constants/constants.dart';

class StudentNoticePage extends StatefulWidget {
  final String classCode;
  final String className;

  const StudentNoticePage({
    Key? key,
    required this.classCode,
    required this.className,
  }) : super(key: key);

  @override
  _StudentNoticePageState createState() => _StudentNoticePageState();
}

class _StudentNoticePageState extends State<StudentNoticePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notices = [];

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final token = getToken();
      final res = await http.get(
        Uri.parse('$baseUrl/students/notices/${widget.classCode}'),
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

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.warning_rounded;
      case 'important':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
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

  void _showNoticeDetail(Map<String, dynamic> notice) {
    final priority = notice['priority'] ?? 'normal';
    final color = _getPriorityColor(priority);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getPriorityIcon(priority),
                            size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          priority.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notice['title'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(notice['createdAt'] ?? ''),
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
              const Divider(height: 24),
              Text(
                notice['message'] ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sent by',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(
                          notice['teacherName'] ?? 'Teacher',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF7),
      body: Column(
        children: [
          Header(
            heading: 'Notices',
            subheading: widget.className,
          ),
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
                  Text(
                    'No notices yet',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your teacher hasn\'t sent any notices',
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchNotices,
              color: const Color(0xFF00A76F),
              child: ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _notices.length,
                itemBuilder: (context, index) {
                  final notice = _notices[index];
                  final priority =
                      notice['priority'] ?? 'normal';
                  final color = _getPriorityColor(priority);
                  final isUrgent = priority == 'urgent';

                  return GestureDetector(
                    onTap: () => _showNoticeDetail(notice),
                    child: Container(
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? Colors.red.shade50
                            : Colors.white,
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
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Icon(
                                _getPriorityIcon(priority),
                                color: color,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notice['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(notice[
                                      'createdAt'] ??
                                          ''),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                        Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notice['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'By ${notice['teacherName'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 18),
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