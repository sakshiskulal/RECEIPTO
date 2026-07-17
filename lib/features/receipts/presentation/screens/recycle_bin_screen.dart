import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/features/scan/data/repositories/scan_repository.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isPerformingCleanup = false;
  bool _isOperationLoading = false;

  @override
  void initState() {
    super.initState();
    // Run auto-cleanup when opening the Recycle Bin
    Future.microtask(() => _runAutoCleanup());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Automatically deletes receipts older than 30 days
  Future<void> _runAutoCleanup() async {
    setState(() => _isPerformingCleanup = true);
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final userId = authService.currentUser?.uid;
      if (userId == null) return;

      final dbService = ref.read(receiptDatabaseServiceProvider);
      final repo = ref.read(scanRepositoryProvider);

      final oldReceipts = await dbService.fetchOldDeletedReceipts(userId: userId);
      if (oldReceipts.isNotEmpty) {
        if (kDebugMode) print('Auto-cleanup: permanently deleting ${oldReceipts.length} stale receipts');
        for (final row in oldReceipts) {
          final idStr = row['id'].toString();
          final imageUrl = row['image_url'] as String?;
          await repo.permanentDeleteReceipt(receiptId: idStr, imageUrl: imageUrl);
        }
        ref.invalidate(recycleBinProvider);
        ref.invalidate(dbReceiptsListProvider);
        ref.invalidate(dbWarrantiesProvider);
        ref.invalidate(notificationNotifierProvider);
      }
    } catch (e) {
      if (kDebugMode) print('Auto-cleanup failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isPerformingCleanup = false);
      }
    }
  }

  /// Handles restoration of a receipt
  Future<void> _handleRestore(Map<String, dynamic> row) async {
    setState(() => _isOperationLoading = true);
    final receiptId = row['id'].toString();
    try {
      await ref.read(scanRepositoryProvider).restoreReceipt(receiptId);
      ref.invalidate(recycleBinProvider);
      ref.invalidate(dbReceiptsListProvider);
      ref.invalidate(dbWarrantiesProvider);
      ref.invalidate(notificationNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt Restored'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOperationLoading = false);
      }
    }
  }

  /// Handles permanent deletion of a receipt
  Future<void> _handleDeletePermanently(Map<String, dynamic> row) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Delete Permanently?',
          style: GoogleFonts.hankenGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This action cannot be undone.\nThe following will be removed permanently:\n• Receipt\n• Receipt Items\n• Warranty\n• Receipt Image\n• Reminder Schedules\n• Email Reminder Flags',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.sm,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete Forever',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isOperationLoading = true);
    final receiptId = row['id'].toString();
    final imageUrl = row['image_url'] as String?;
    try {
      await ref.read(scanRepositoryProvider).permanentDeleteReceipt(
        receiptId: receiptId,
        imageUrl: imageUrl,
      );
      ref.invalidate(recycleBinProvider);
      ref.invalidate(dbReceiptsListProvider);
      ref.invalidate(dbWarrantiesProvider);
      ref.invalidate(notificationNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt Permanently Deleted'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOperationLoading = false);
      }
    }
  }

  /// Handles Empty Bin action
  Future<void> _handleEmptyBin(List<Map<String, dynamic>> deletedReceipts) async {
    if (deletedReceipts.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(
          'Empty Bin?',
          style: GoogleFonts.hankenGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Delete ALL permanently?\nThis action cannot be undone and will delete every receipt inside the recycle bin.',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.sm,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete All',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isOperationLoading = true);
    try {
      final repo = ref.read(scanRepositoryProvider);
      for (final row in deletedReceipts) {
        final idStr = row['id'].toString();
        final imageUrl = row['image_url'] as String?;
        await repo.permanentDeleteReceipt(receiptId: idStr, imageUrl: imageUrl);
      }
      ref.invalidate(recycleBinProvider);
      ref.invalidate(dbReceiptsListProvider);
      ref.invalidate(dbWarrantiesProvider);
      ref.invalidate(notificationNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recycle Bin Emptied'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empty Bin failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOperationLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Fetch soft-deleted receipts using the dedicated recycleBinProvider
    final receiptsAsync = ref.watch(recycleBinProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recycle Bin',
          style: GoogleFonts.hankenGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Empty Bin action
          receiptsAsync.when(
            data: (deletedRows) {
              if (deletedRows.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                label: Text(
                  'Empty Bin',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => _handleEmptyBin(deletedRows),
              );
            },
            error: (_, __) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: receiptsAsync.when(
          data: (deletedRows) {
            // Apply search filter
            final filteredRows = deletedRows.where((row) {
              final merchant = (row['merchant_name'] as String? ?? '').toLowerCase();
              final category = (row['category'] as String? ?? '').toLowerCase();
              final query = _searchQuery.toLowerCase();
              return merchant.contains(query) || category.contains(query);
            }).toList();

            // Sort newest deleted first
            filteredRows.sort((a, b) {
              final aDel = a['deleted_at'] as String? ?? '';
              final bDel = b['deleted_at'] as String? ?? '';
              return bDel.compareTo(aDel);
            });

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: AppSpacing.sm),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: AppRadius.md,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                cursorColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                style: GoogleFonts.inter(
                                  color: AppColors.onSurface,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search deleted receipts...',
                                  hintStyle: GoogleFonts.inter(
                                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Main Content List
                    Expanded(
                      child: filteredRows.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty ? 'Recycle Bin is empty' : 'No matching receipts found',
                                style: GoogleFonts.inter(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.gutter),
                              itemCount: filteredRows.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final row = filteredRows[index];
                                final merchant = row['merchant_name'] as String? ?? 'Unknown Merchant';
                                final date = row['date'] as String? ?? 'Unknown Date';
                                final total = ReceiptModel.parseDouble(row['grand_total']) ?? 
                                    ReceiptModel.parseDouble(row['total']) ?? 
                                    0.0;
                                final currency = row['currency'] as String? ?? '₹';
                                final imageUrl = row['image_url'] as String?;
                                final deletedAtStr = row['deleted_at'] as String?;

                                // Calculate remaining days
                                int daysDeleted = 0;
                                int daysRemaining = 30;
                                if (deletedAtStr != null) {
                                  final delDateTime = DateTime.tryParse(deletedAtStr);
                                  if (delDateTime != null) {
                                    final diff = DateTime.now().difference(delDateTime);
                                    daysDeleted = diff.inDays;
                                    daysRemaining = 30 - daysDeleted;
                                    if (daysRemaining < 0) daysRemaining = 0;
                                  }
                                }

                                final daysDeletedText = daysDeleted == 0 
                                    ? 'Deleted today' 
                                    : (daysDeleted == 1 ? 'Deleted 1 day ago' : 'Deleted $daysDeleted days ago');

                                return GlassCard(
                                  borderRadius: AppRadius.lg,
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Image thumbnail
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: AppRadius.md,
                                          image: imageUrl != null && imageUrl.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(imageUrl),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: imageUrl == null || imageUrl.isEmpty
                                            ? const Icon(Icons.receipt_long, color: AppColors.primary)
                                            : null,
                                      ),
                                      const SizedBox(width: 14),

                                      // Text Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              merchant,
                                              style: GoogleFonts.hankenGrotesk(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Purchased: $date',
                                              style: textTheme.codeSm.copyWith(
                                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Deleted meta
                                            Text(
                                              '$daysDeletedText • $daysRemaining days left',
                                              style: GoogleFonts.inter(
                                                color: Colors.orangeAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Amount & Action buttons column
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(total, currency: currency),
                                            style: GoogleFonts.hankenGrotesk(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              // Restore Button
                                              IconButton(
                                                icon: const Icon(Icons.settings_backup_restore_rounded, color: Colors.greenAccent),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _handleRestore(row),
                                                tooltip: 'Restore',
                                              ),
                                              const SizedBox(width: 16),
                                              // Delete Forever Button
                                              IconButton(
                                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _handleDeletePermanently(row),
                                                tooltip: 'Delete Forever',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // Absolute loading indicators
                if (_isOperationLoading || _isPerformingCleanup)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
              ],
            );
          },
          error: (err, _) => Center(
            child: Text(
              'Error loading Recycle Bin: $err',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
