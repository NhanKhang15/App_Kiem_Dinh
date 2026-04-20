import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfEmbedView extends StatefulWidget {
  const PdfEmbedView({
    super.key,
    required this.pdfBytes,
  });

  final Uint8List pdfBytes;

  @override
  State<PdfEmbedView> createState() => _PdfEmbedViewState();
}

class _PdfEmbedViewState extends State<PdfEmbedView> {
  PDFViewController? _controller;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PDFView(
          pdfData: widget.pdfBytes,
          swipeHorizontal: true,
          pageFling: true,
          autoSpacing: true,
          pageSnap: true,
          onRender: (pages) {
            if (pages != null) setState(() => _totalPages = pages);
          },
          onViewCreated: (controller) => _controller = controller,
          onPageChanged: (page, total) {
            if (page != null) setState(() => _currentPage = page);
          },
        ),
        if (_totalPages > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _currentPage > 0
                      ? () => _controller?.setPage(_currentPage - 1)
                      : null,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: _currentPage < _totalPages - 1
                      ? () => _controller?.setPage(_currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? Colors.black54 : Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white38,
          size: 22,
        ),
      ),
    );
  }
}
