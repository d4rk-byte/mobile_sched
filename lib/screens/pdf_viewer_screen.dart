import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../utils/theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String filePath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.filePath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isReady = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 56,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            PDFView(
              filePath: widget.filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _isReady = true;
                  _totalPages = pages ?? 0;
                });
              },
              onError: (error) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _errorMessage = 'Failed to load PDF: $error';
                  _isReady = true;
                });
              },
              onPageError: (page, error) {
                if (!mounted) {
                  return;
                }

                final safePage = page ?? 0;

                setState(() {
                  _errorMessage =
                      'Failed to render page ${safePage + 1}: $error';
                  _isReady = true;
                });
              },
              onPageChanged: (page, total) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _currentPage = page ?? 0;
                  _totalPages = total ?? _totalPages;
                });
              },
            ),
          if (!_isReady)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_isReady && _errorMessage == null && _totalPages > 0)
            Positioned(
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Page ${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
