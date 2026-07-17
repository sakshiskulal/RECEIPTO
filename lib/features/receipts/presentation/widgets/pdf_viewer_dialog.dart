import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:receipto/core/constants/constants.dart';

class PdfViewerDialog extends StatefulWidget {
  final String pdfUrl;
  const PdfViewerDialog({super.key, required this.pdfUrl});

  @override
  State<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<PdfViewerDialog> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF document.');
      }
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_view_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(response.bodyBytes);

      _pdfController = PdfController(
        document: PdfDocument.openFile(tempFile.path),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        color: Colors.black.withValues(alpha: 0.9),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : _error != null
                    ? Center(child: Text('Error loading PDF: $_error', style: const TextStyle(color: Colors.white)))
                    : PdfView(
                        controller: _pdfController!,
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
