import 'dart:io';
import 'package:flutter/material.dart';
import 'package:present_me_flutter/core/widgets/header.dart';
import 'download_manager.dart';
import 'pdf_viewer_screen.dart';

class DownloadedNotesScreen extends StatefulWidget {
  const DownloadedNotesScreen({super.key});

  @override
  State<DownloadedNotesScreen> createState() => _DownloadedNotesScreenState();
}

class _DownloadedNotesScreenState extends State<DownloadedNotesScreen> {
  List<DownloadedNote> _downloads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => _downloads = DownloadManager.getAllDownloaded());

  Color _typeColor(String t) => t == 'PYQ' ? const Color(0xFF059669) : const Color(0xFF3B4FE0);
  Color _typeBg(String t)    => t == 'PYQ' ? const Color(0xFFD1FAE5) : const Color(0xFFEEF2FF);

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

  Future<void> _delete(DownloadedNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Download?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Remove "${note.title}" from your downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DownloadManager.delete(note.noteId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          Header(
            heading: 'My Downloads',
            subheading: 'Saved notes — available offline',
          ),
          Expanded(
            child: _downloads.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _downloads.length,
                    itemBuilder: (ctx, i) => _buildCard(_downloads[i]),
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
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.download_done_rounded, size: 64, color: Color(0xFF3B4FE0)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Downloads Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Files you download will appear here\nand work without internet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(DownloadedNote note) {
    final fileExists = File(note.localPath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: fileExists
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        localPath: note.localPath,
                        title:     note.title,
                      ),
                    ),
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Icon ──
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _typeBg(note.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    note.type == 'PYQ' ? Icons.menu_book_outlined : Icons.picture_as_pdf_outlined,
                    color: _typeColor(note.type), size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5, runSpacing: 4,
                        children: [
                          _badge(note.type,     _typeBg(note.type),      _typeColor(note.type)),
                          _badge(note.semester, const Color(0xFFF1F5F9), Colors.black45),
                          _badge(note.department, const Color(0xFFEEF2FF), const Color(0xFF3B4FE0)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 11, color: Colors.black38),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Downloaded ${_formatDate(note.downloadedAt)}',
                              style: const TextStyle(fontSize: 11, color: Colors.black38),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // ── Offline badge ──
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_pin_rounded, size: 10, color: Color(0xFF059669)),
                                SizedBox(width: 3),
                                Text('Offline', style: TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Actions ──
                Column(
                  children: [
                    // Open button
                    if (fileExists)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3B4FE0), Color(0xFF6B4FE8)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Open', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    if (!fileExists)
                      const Text('File missing', style: TextStyle(fontSize: 11, color: Colors.red)),
                    const SizedBox(height: 8),
                    // Delete button
                    GestureDetector(
                      onTap: () => _delete(note),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red.shade400, size: 13),
                            const SizedBox(width: 4),
                            Text('Remove', style: TextStyle(color: Colors.red.shade400, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
