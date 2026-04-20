import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

import 'pdf_embed_view.dart';

class InAppDocumentViewer extends StatefulWidget {
  const InAppDocumentViewer({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<InAppDocumentViewer> createState() => _InAppDocumentViewerState();
}

class _InAppDocumentViewerState extends State<InAppDocumentViewer> {
  late Future<Uint8List> _pdfFuture;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _pdfFuture = _fetchPdfBytes();
  }

  Future<Uint8List> _fetchPdfBytes() async {
    final session = await AuthStorage.getSavedSession();
    final api = ApiClient.instance;
    if (session != null && session.token.isNotEmpty) {
      api.setAuthToken(session.token);
    }

    final response = await api.dio.get<List<int>>(
      'orders/${widget.orderId}/download-contract-pdf/',
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.data == null || response.data!.isEmpty) {
      throw Exception('Khong tai duoc file PDF tu server.');
    }

    return Uint8List.fromList(response.data!);
  }

  Future<void> _sharePdf() async {
    if (_isSharing) {
      return;
    }

    setState(() {
      _isSharing = true;
    });

    try {
      final pdfBytes = await _pdfFuture;
      final fileName = 'hop_dong_don_hang_${widget.orderId}.pdf';

      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf')],
        subject: 'Hop dong don hang ${widget.orderId}',
        text: 'Hop dong don hang ${widget.orderId}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khong the chia se file PDF: $error'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _reloadPdf() {
    setState(() {
      _pdfFuture = _fetchPdfBytes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF1D4ED8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tai lieu don hang (PDF)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSharing ? null : _sharePdf,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(_isSharing ? 'Dang chia se' : 'Chia se'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Xem truc tiep hop dong PDF duoc tai ve tu he thong.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 520,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<Uint8List>(
                future: _pdfFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                          SizedBox(height: 12),
                          Text(
                            'Dang tai hop dong PDF...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Khong the tai PDF.\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _reloadPdf,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Thu lai'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return PdfEmbedView(pdfBytes: snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
