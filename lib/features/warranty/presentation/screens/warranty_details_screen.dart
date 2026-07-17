import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/nebula_background.dart';
import 'package:receipto/core/widgets/gradient_button.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/core/utils/warranty_utils.dart';

class WarrantyDetailsScreen extends ConsumerWidget {
  final String warrantyId;

  const WarrantyDetailsScreen({
    super.key,
    required this.warrantyId,
  });

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.greenAccent;
      case 'EXPIRING_SOON':
      case 'EXPIRING SOON':
        return Colors.orangeAccent;
      case 'EXPIRED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warrantyAsync = ref.watch(warrantyDetailProvider(warrantyId));

    return warrantyAsync.when(
      data: (warranty) {
        if (warranty == null) {
          return _buildErrorScreen(context, 'Warranty record not found.');
        }
        return _buildDetailsContent(context, warranty);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      ),
      error: (err, stack) => _buildErrorScreen(context, err.toString()),
    );
  }

  Widget _buildDetailsContent(BuildContext context, WarrantyModel warranty) {
    final statusColor = _getStatusColor(warranty.status);
    final daysRemaining = WarrantyUtils.calculateDaysRemaining(warranty.expiryDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Nebula animation
          const Positioned.fill(
            child: AnimatedNebulaBackground(opacity: 0.5),
          ),
          
          // Vignette overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.4),
                    AppColors.background.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header
                _buildHeader(context),
                
                // Details Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gutter,
                      vertical: AppSpacing.base,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Receipt Scan Image Preview
                        _buildReceiptImagePreview(context, warranty.imageUrl ?? ''),
                        const SizedBox(height: 24),

                        // Product Name & Status Header Card
                        _buildProductHeaderCard(context, warranty, statusColor),
                        const SizedBox(height: 20),

                        // Specifications & Metadata Card
                        _buildMetadataCard(context, warranty, daysRemaining),
                        const SizedBox(height: 20),

                        // Notes & Remarks Card
                        _buildNotesCard(context),
                        const SizedBox(height: 32),

                        // Action button to open original receipt
                        if (warranty.receiptId != null)
                          GradientButton(
                            text: 'Open Original Receipt',
                            onPressed: () {
                              context.push('/receipts/details/${warranty.receiptId}');
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.onSurface,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
          ),
          Text(
            'Warranty Details',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40), // Balance Spacer
        ],
      ),
    );
  }

  Widget _buildProductHeaderCard(BuildContext context, WarrantyModel warranty, Color statusColor) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            warranty.productName,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            warranty.merchantName,
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: AppRadius.full,
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  warranty.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, WarrantyModel warranty, int daysRemaining) {
    final String daysText = daysRemaining >= 0 ? '$daysRemaining Days' : 'Expired';
    final String unitText = warranty.warrantyUnit.toLowerCase();

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (warranty.brand != null && warranty.brand!.isNotEmpty)
            _buildMetadataRow('Brand', warranty.brand!),
          if (warranty.model != null && warranty.model!.isNotEmpty)
            _buildMetadataRow('Model', warranty.model!),
          if (warranty.serialNumber != null && warranty.serialNumber!.isNotEmpty)
            _buildMetadataRow('Serial Number', warranty.serialNumber!),
          _buildMetadataRow('Warranty Period', '${warranty.warrantyPeriod} ${unitText[0].toUpperCase()}${unitText.substring(1)}'),
          _buildMetadataRow('Purchase Date', warranty.purchaseDate),
          _buildMetadataRow('Expiry Date', warranty.expiryDate),
          _buildMetadataRow('Days Remaining', daysText, highlightValue: true, isExpired: daysRemaining < 0),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, {bool highlightValue = false, bool isExpired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: highlightValue 
                  ? (isExpired ? Colors.redAccent : AppColors.primary)
                  : AppColors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes & Remarks',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Warranty status verified dynamically. Keep original scanned invoice copy below for replacement claims and support services.',
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImagePreview(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          color: AppColors.surfaceVariant,
        ),
        child: const Center(
          child: Icon(Icons.receipt_long_outlined, color: AppColors.onSurfaceVariant, size: 48),
        ),
      );
    }

    final String filename = imageUrl.split('/').last.split('?').first.toLowerCase();
    final String extension = filename.split('.').last;
    
    final bool isImage = ['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension);
    final bool isPdf = extension == 'pdf';

    return GestureDetector(
      onTap: () {
        if (isImage) {
          _showFullScreenImage(context, imageUrl);
        } else if (isPdf) {
          _showPdfViewer(context, imageUrl);
        } else {
          _showDocumentViewer(context, imageUrl);
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.lg,
          child: Stack(
            children: [
              Positioned.fill(
                child: isImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(color: AppColors.secondary));
                        },
                      )
                    : Container(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.2),
                        child: Center(
                          child: Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
                            color: AppColors.primary,
                            size: 48,
                          ),
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: [
                    const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isImage ? 'Tap to Zoom Invoice' : 'Tap to View Original Scan',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.9),
                  child: InteractiveViewer(
                    maxScale: 4.0,
                    child: Image.network(imageUrl),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 20.0),
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
      ),
    );
  }

  void _showPdfViewer(BuildContext context, String pdfUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _PdfViewerDialog(pdfUrl: pdfUrl),
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, String fileUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _DocumentViewerDialog(fileUrl: fileUrl),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              error,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfViewerDialog extends StatefulWidget {
  final String pdfUrl;
  const _PdfViewerDialog({required this.pdfUrl});

  @override
  State<_PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<_PdfViewerDialog> {
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
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

class _DocumentViewerDialog extends StatefulWidget {
  final String fileUrl;
  const _DocumentViewerDialog({required this.fileUrl});

  @override
  State<_DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<_DocumentViewerDialog> {
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
      
      final String filename = widget.fileUrl.split('/').last.split('?').first;
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
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
