import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_storage/get_storage.dart';
import 'package:present_me_flutter/core/widgets/header.dart';

import '../../../viewmodels/notes/notes_bloc.dart';
import '../../../viewmodels/notes/notes_event.dart';
import '../../../viewmodels/notes/notes_state.dart';
import 'Notes&PYQ.dart';

class MyUploadsScreen extends StatefulWidget {
  const MyUploadsScreen({super.key});

  @override
  State<MyUploadsScreen> createState() => _MyUploadsScreenState();
}

class _MyUploadsScreenState extends State<MyUploadsScreen> {
  final GetStorage _storage = GetStorage();
  String _getToken() => _storage.read('token')?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesBloc>().add(FetchMyUploads(token: _getToken()));
    });
  }

  Color _typeColor(String t) => t == 'PYQ' ? const Color(0xFF059669) : const Color(0xFF3B4FE0);
  Color _typeBg(String t)    => t == 'PYQ' ? const Color(0xFFD1FAE5) : const Color(0xFFEEF2FF);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF059669);
      case 'rejected': return const Color(0xFFDC2626);
      default:         return const Color(0xFFF59E0B); // pending
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFFD1FAE5);
      case 'rejected': return const Color(0xFFFEE2E2);
      default:         return const Color(0xFFFEF3C7); // pending
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default:         return Icons.hourglass_empty_rounded;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          Header(
            heading: 'My Uploads',
            subheading: 'Track your submitted study materials',
          ),
          Expanded(
            child: BlocBuilder<NotesBloc, NotesState>(
              buildWhen: (prev, curr) =>
              curr is MyUploadsLoading ||
                  curr is MyUploadsFetchSuccess ||
                  curr is MyUploadsFetchError,
              builder: (context, state) {
                if (state is MyUploadsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B4FE0)),
                  );
                }

                if (state is MyUploadsFetchError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.black38, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message,
                          style: const TextStyle(color: Colors.black45, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<NotesBloc>()
                              .add(FetchMyUploads(token: _getToken())),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B4FE0)),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                if (state is MyUploadsFetchSuccess) {
                  if (state.notes.isEmpty) return _buildEmpty();
                  return RefreshIndicator(
                    color: const Color(0xFF3B4FE0),
                    onRefresh: () async {
                      context.read<NotesBloc>().add(FetchMyUploads(token: _getToken()));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notes.length,
                      itemBuilder: (ctx, i) => _buildCard(state.notes[i]),
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file_rounded, size: 64, color: Color(0xFF3B4FE0)),
          ),
          const SizedBox(height: 20),
          const Text('No Uploads Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text(
            'Files you submit will appear here\nwith their approval status.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(NoteModel note) {
    // NoteModel.fromJson maps status from json — make sure your fromJson includes it
    final status = (note as dynamic).status as String? ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon ──
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _typeBg(note.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  note.type == 'PYQ' ? Icons.menu_book_outlined : Icons.description_outlined,
                  color: _typeColor(note.type), size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: [
                        _badge(note.type,       _typeBg(note.type),      _typeColor(note.type)),
                        _badge(note.semester,   const Color(0xFFF1F5F9), Colors.black45),
                        _badge(note.department, const Color(0xFFEEF2FF), const Color(0xFF3B4FE0)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ── Status badge ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
                    const SizedBox(width: 4),
                    Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              // downloads
              const Icon(Icons.download_rounded, size: 14, color: Color(0xFF3B4FE0)),
              const SizedBox(width: 4),
              Text('${note.downloads} downloads',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF3B4FE0), fontWeight: FontWeight.w600)),
              const Spacer(),
              // date
              const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.black38),
              const SizedBox(width: 4),
              Text(_formatDate(note.date),
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}