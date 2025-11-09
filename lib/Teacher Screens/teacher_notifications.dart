import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TeacherNotificationsPage extends StatefulWidget {
  const TeacherNotificationsPage({super.key});

  @override
  State<TeacherNotificationsPage> createState() => _TeacherNotificationsPageState();
}

class _TeacherNotificationsPageState extends State<TeacherNotificationsPage> {
  String _filter = 'All'; // All | Unread | Mentions (reserved)

  User? get _user => FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream() {
    if (_user == null) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    final base = FirebaseFirestore.instance
        .collection('teachers')
        .doc(_user!.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true);

    if (_filter == 'Unread') {
      return base.where('isRead', isEqualTo: false).snapshots();
    }
    return base.snapshots();
  }

  Future<void> _markAllAsRead() async {
    if (_user == null) return;
    final qs = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(_user!.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in qs.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays}d ago';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'alert':
        return const Color(0xFFEF4444); // red
      case 'class':
        return const Color(0xFF3B82F6); // blue
      case 'message':
        return const Color(0xFF8B5CF6); // purple
      case 'achievement':
        return const Color(0xFF10B981); // green
      default:
        return const Color(0xFF06B6D4); // cyan
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'class':
        return Icons.class_outlined;
      case 'message':
        return Icons.mail_outline;
      case 'achievement':
        return Icons.emoji_events_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFECFEFF), Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(top: 52, left: 20, right: 20, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay updated with Present-Me',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filter == 'All',
                          onTap: () => setState(() => _filter = 'All'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Unread',
                          selected: _filter == 'Unread',
                          onTap: () => setState(() => _filter = 'Unread'),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          onPressed: _markAllAsRead,
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Mark all read'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Notifications stream
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _notificationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _SkeletonList();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _EmptyState(
                        onExplore: () => setState(() => _filter = 'All'),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  // Group by day label
                  final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> groups = {};
                  for (final d in docs) {
                    final ts = (d.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final label = _dayLabel(ts);
                    groups.putIfAbsent(label, () => []).add(d);
                  }

                  final sections = groups.entries.toList();
                  sections.sort((a, b) => _sectionOrder(a.key).compareTo(_sectionOrder(b.key)));

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final label = sections[index].key;
                      final items = sections[index].value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          ...items.map((doc) => _NotificationTile(
                                data: doc.data(),
                                onDelete: () => doc.reference.delete(),
                                onToggleRead: () => doc.reference.update({
                                  'isRead': !(doc.data()['isRead'] as bool? ?? false),
                                }),
                                timeAgo: _timeAgo(((doc.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now())),
                                color: _typeColor(doc.data()['type']?.toString() ?? 'info'),
                                icon: _typeIcon(doc.data()['type']?.toString() ?? 'info'),
                              )),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return 'Earlier';
  }

  int _sectionOrder(String label) {
    switch (label) {
      case 'Today':
        return 0;
      case 'Yesterday':
        return 1;
      default:
        return 2;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  final VoidCallback onToggleRead;
  final String timeAgo;
  final Color color;
  final IconData icon;

  const _NotificationTile({
    required this.data,
    required this.onDelete,
    required this.onToggleRead,
    required this.timeAgo,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Notification';
    final body = data['body']?.toString() ?? '';
    final isRead = data['isRead'] as bool? ?? false;

    return Dismissible(
      key: ValueKey(data['id'] ?? title + timeAgo),
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          children: [Icon(Icons.mark_email_read_outlined, color: Colors.white), SizedBox(width: 8), Text('Mark read', style: TextStyle(color: Colors.white))],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [Icon(Icons.delete_outline, color: Colors.white), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.white))],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onToggleRead();
          return false; // keep item, just toggled
        }
        // right to left -> delete
        onDelete();
        return true;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            decoration: isRead ? TextDecoration.none : TextDecoration.none,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.3),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const Spacer(),
                      TextButton(
                        onPressed: onToggleRead,
                        child: Text(isRead ? 'Mark unread' : 'Mark read'),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('No notifications yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        Text('You\'re all caught up. New updates will appear here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 12, color: Colors.grey.shade200),
                    const SizedBox(height: 8),
                    Container(width: MediaQuery.of(context).size.width * 0.5, height: 10, color: Colors.grey.shade200),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
