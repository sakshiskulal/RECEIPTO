import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:receipto/core/constants/constants.dart';

class DocumentViewerDialog extends StatefulWidget {
  final String fileUrl;
  const DocumentViewerDialog({super.key, required this.fileUrl});

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  String _content = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download document.');
      }
      
      final tempDir = await getTemporaryDirectory();
      final String filename = widget.fileUrl.split('/').last.split('?').first;
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(response.bodyBytes);

      final String ext = filename.split('.').last.toLowerCase();
      String parsedText = '';

      if (ext == 'docx') {
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);
        final docFile = archive.findFile('word/document.xml');
        if (docFile != null) {
          final xmlStr = utf8.decode(docFile.content as List<int>);
          final document = xml.XmlDocument.parse(xmlStr);
          parsedText = document.findAllElements('w:t').map((node) => node.innerText).join('\n');
        }
      } else if (ext == 'xlsx') {
        final archive = ZipDecoder().decodeBytes(response.bodyBytes);
        final List<String> sharedStrings = [];
        final stringsFile = archive.findFile('xl/sharedStrings.xml');
        if (stringsFile != null) {
          final xmlStr = utf8.decode(stringsFile.content as List<int>);
          final document = xml.XmlDocument.parse(xmlStr);
          for (final node in document.findAllElements('t')) {
            sharedStrings.add(node.innerText);
          }
        }
        final sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
        if (sheetFile != null) {
          final xmlStr = utf8.decode(sheetFile.content as List<int>);
          final document = xml.XmlDocument.parse(xmlStr);
          final List<String> rows = [];
          for (final rowNode in document.findAllElements('row')) {
            final List<String> cells = [];
            for (final cellNode in rowNode.findElements('c')) {
              final String? type = cellNode.getAttribute('t');
              final valNode = cellNode.findElements('v').firstOrNull;
              if (valNode != null) {
                final String val = valNode.innerText;
                if (type == 's') {
                  final int idx = int.tryParse(val) ?? -1;
                  if (idx >= 0 && idx < sharedStrings.length) {
                    cells.add(sharedStrings[idx]);
                  } else {
                    cells.add('');
                  }
                } else {
                  cells.add(val);
                }
              } else {
                cells.add('');
              }
            }
            rows.add(cells.join(' | '));
          }
          parsedText = rows.join('\n');
        }
      } else if (['txt', 'csv'].contains(ext)) {
        parsedText = utf8.decode(response.bodyBytes);
      } else {
        // Binary scan search
        final buffer = StringBuffer();
        int consecutivePrintable = 0;
        final currentWord = StringBuffer();
        
        for (final byte in response.bodyBytes) {
          if (byte >= 32 && byte <= 126) {
            currentWord.writeCharCode(byte);
            consecutivePrintable++;
          } else {
            if (consecutivePrintable >= 4) {
              buffer.write(currentWord.toString());
              buffer.write(' ');
            }
            currentWord.clear();
            consecutivePrintable = 0;
          }
        }
        parsedText = buffer.toString();
      }

      setState(() {
        _content = parsedText.isNotEmpty ? parsedText : 'Empty document contents.';
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
            padding: const EdgeInsets.only(top: 50.0, left: 16, right: 16, bottom: 16),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : _error != null
                    ? Center(child: Text('Error loading document: $_error', style: const TextStyle(color: Colors.white)))
                    : SingleChildScrollView(
                        child: Text(
                          _content,
                          style: GoogleFonts.firaCode(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
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
