import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewerScreen extends StatefulWidget {
  final String localPath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.localPath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _totalPages   = 0;
  int _currentPage  = 0;
  bool _isReady     = false;
  PDFViewController? _controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            if (_isReady)
              Text(
                'Page ${_currentPage + 1} of $_totalPages',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
        actions: [
          // Go to first page
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white70),
            onPressed: () => _controller?.setPage(0),
          ),
          // Go to last page
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white70),
            onPressed: () => _controller?.setPage(_totalPages - 1),
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.localPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: true, // ✅ block external links
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
                _isReady    = true;
              });
            },
            onViewCreated: (controller) {
              _controller = controller;
            },
            onPageChanged: (page, total) {
              setState(() => _currentPage = page ?? 0);
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red),
              );
            },
          ),

          // ── Loading overlay ──
          if (!_isReady)
            Container(
              color: const Color(0xFF1E1E2E),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF3B4FE0)),
                    SizedBox(height: 16),
                    Text('Loading PDF...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),

      // ── Page navigation bar ──
      bottomNavigationBar: _isReady
          ? Container(
              color: const Color(0xFF2D2D44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _currentPage > 0
                        ? () => _controller?.setPage(_currentPage - 1)
                        : null,
                  ),
                  Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _currentPage < _totalPages - 1
                        ? () => _controller?.setPage(_currentPage + 1)
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
