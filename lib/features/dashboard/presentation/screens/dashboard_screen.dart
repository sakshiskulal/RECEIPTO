import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/features/dashboard/presentation/widgets/sparkline_widget.dart';
import 'package:receipto/features/dashboard/presentation/widgets/receipt_list_item.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/utils/currency_formatter.dart';
import 'package:receipto/features/warranty/presentation/providers/warranty_provider.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';
import 'package:receipto/features/notifications/presentation/providers/notification_provider.dart';
import 'package:receipto/core/utils/warranty_utils.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grocery': return Icons.shopping_cart;
      case 'food': return Icons.restaurant;
      case 'fuel': return Icons.local_gas_station;
      case 'shopping': return Icons.shopping_bag;
      case 'medical': return Icons.medical_services;
      case 'bills': return Icons.bolt;
      default: return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(dbReceiptsListProvider);
    final warrantiesAsync = ref.watch(dbWarrantiesProvider);

    double totalSpending = 0.0;
    double totalSaved = 0.0;
    final List<Map<String, dynamic>> allRows = receiptsAsync.value ?? [];

    for (final r in allRows) {
      final double amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      final double disc = ReceiptModel.parseDouble(r['discount']) ?? 0.0;
      totalSpending += amt;
      totalSaved += disc;
    }

    final List<WarrantyModel> warranties = warrantiesAsync.value ?? [];
    final protectedProductsCount = warranties.length;
    final activeCount = warranties.where((w) => w.status == 'ACTIVE').length;
    final expiringSoonCount = warranties.where((w) => w.status == 'EXPIRING SOON').length;
    final expiredCount = warranties.where((w) => w.status == 'EXPIRED').length;

    final List<ReceiptData> recentReceipts = allRows.map((row) {
      final double amt = ReceiptModel.parseDouble(row['grand_total']) ?? ReceiptModel.parseDouble(row['total']) ?? 0.0;
      final String category = row['category'] as String? ?? 'Other';
      return ReceiptData(
        id: row['id'].toString(),
        merchant: row['merchant_name'] as String? ?? 'Unknown Merchant',
        date: row['date'] as String? ?? 'Unknown Date',
        amount: -amt, // Negative values match spending display in Dashboard screen
        category: category,
        icon: _getCategoryIcon(category),
        currency: row['currency'] as String?,
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar Space
                  _buildHeader(context, ref),
                  const SizedBox(height: 20),

                  // Greeting Info
                  _buildGreeting(context, ref),
                  const SizedBox(height: 24),

                  // Monthly Spending Hero Card
                  _buildMonthlySpendingCard(context, totalSpending),
                  const SizedBox(height: 24),

                  // Stats Grid (Total Saved & Receipts Scanned)
                  _buildStatsGrid(context, totalSaved, recentReceipts.length),
                  const SizedBox(height: 24),

                  // Warranty Overview Premium Glass Card
                  Builder(
                    builder: (context) {
                      final List<WarrantyModel> nonExpiredWarranties = warranties.where((w) => w.status != 'EXPIRED').toList();
                      nonExpiredWarranties.sort((a, b) {
                        try {
                          final da = DateTime.parse(a.expiryDate);
                          final db = DateTime.parse(b.expiryDate);
                          return da.compareTo(db);
                        } catch (_) {
                          return 0;
                        }
                      });
                      final nextExpiring = nonExpiredWarranties.isNotEmpty ? nonExpiredWarranties.first : null;

                      return _buildWarrantyOverviewCard(
                        context,
                        total: protectedProductsCount,
                        active: activeCount,
                        expiring: expiringSoonCount,
                        expired: expiredCount,
                        nextExpiring: nextExpiring,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // AI Suggestions Card
                  _buildAISuggestion(context),
                  const SizedBox(height: 24),

                  // Recent Receipts Title & List
                  _buildRecentReceiptsHeader(context),
                  const SizedBox(height: 16),
                  _buildReceiptList(context, recentReceipts),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
          
          // Floating Action button overlayed
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildFAB(context),
          ),
        ],
      ),
    );
  }

  // Greeting widget displaying logged-in user name
  Widget _buildGreeting(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final displayName = user?.displayName ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $displayName',
          style: GoogleFonts.hankenGrotesk(
            color: AppColors.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your spending and organize invoices.',
          style: AppFonts.geist(
            color: AppColors.onSurfaceVariant,
            fontSize: 14.5,
            fontWeight: FontWeight.normal,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Custom App Bar Header Row
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Receipto',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        
        ref.watch(unreadNotificationsCountProvider) > 0
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '${ref.watch(unreadNotificationsCountProvider)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.onSurface,
                    size: 22,
                  ),
                  onPressed: () => context.push('/notifications'),
                ),
              ),
      ],
    );
  }

  // Monthly Spending Glass Card with Sparkline visual
  Widget _buildMonthlySpendingCard(BuildContext context, double totalSpending) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          // Decorative background gradient blur blob
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Spending Amount Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Spending',
                        style: textTheme.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(totalSpending),
                        style: textTheme.displayLg.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: AppColors.tertiary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2.4% vs last month',
                            style: textTheme.labelMd.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Sparkline Column charts using containers
                  const SizedBox(
                    width: 120,
                    height: 64,
                    child: SparklineWidget(
                      heights: [0.4, 0.6, 0.5, 0.75, 0.65, 0.9, 1.0],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick statistics grid
  Widget _buildStatsGrid(BuildContext context, double totalSaved, int scannedCount) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        // Card 1: Total Saved
        Expanded(
          child: GlassCard(
            borderRadius: AppRadius.lg,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon wrapper box
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.tertiary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: AppColors.tertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Saved',
                  style: textTheme.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(totalSaved),
                  style: textTheme.headlineLg.copyWith(
                    color: AppColors.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Card 2: Receipts Scanned
        Expanded(
          child: GlassCard(
            borderRadius: AppRadius.lg,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon wrapper box
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.secondary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Receipts Scanned',
                  style: textTheme.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$scannedCount',
                  style: textTheme.headlineLg.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // AI suggestion dialog styled container
  Widget _buildAISuggestion(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: Stack(
          children: [
            // Custom Gradient Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.35),
                      AppColors.cardSurface,
                      const Color(0xFF005236).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Heading row
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI SUGGESTIONS',
                        style: textTheme.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Content text with highlighted dining
                  RichText(
                    text: TextSpan(
                      style: textTheme.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(text: 'Smart Tip: You spent 15% more on '),
                        TextSpan(
                          text: 'Dining',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' this week. Try a budget limit?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Action button outline
                  OutlinedButton(
                    onPressed: () {
                      // Trigger optimization action
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Optimize Budget',
                      style: textTheme.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header row for recent receipts
  Widget _buildRecentReceiptsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Receipts',
          style: textTheme.headlineMd.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        TextButton(
          onPressed: () {
            // Shell routing indexed state navigation to Tab index 1 (Receipts)
            final navigationShell = StatefulNavigationShell.of(context);
            navigationShell.goBranch(1);
          },
          child: Text(
            'View All',
            style: textTheme.labelMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Vertical transaction/receipts list
  Widget _buildReceiptList(BuildContext context, List<ReceiptData> receipts) {
    if (receipts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No recent receipts found.',
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: receipts.length > 5 ? 5 : receipts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = receipts[index];
        return ReceiptListItem(
          data: item,
          onTap: () {
            // Navigate to the newly required detail screen using route:
            // /receipts/details/:id
            context.push('/receipts/details/${item.id}');
          },
        );
      },
    );
  }

  // Floating Action Button
  Widget _buildFAB(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primaryBlueCyan,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary,
            blurRadius: 16,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/scan'),
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(
              Icons.document_scanner_outlined,
              color: AppColors.onPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarrantyOverviewCard(
    BuildContext context, {
    required int total,
    required int active,
    required int expiring,
    required int expired,
    required WarrantyModel? nextExpiring,
  }) {
    return GestureDetector(
      onTap: () => context.push('/warranties'),
      child: GlassCard(
        borderRadius: AppRadius.lg,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Warranty Protection',
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWarrantyStatItem('Protected', '$total', Colors.white),
                _buildWarrantyStatItem('Active', '$active', Colors.greenAccent),
                _buildWarrantyStatItem('Expiring', '$expiring', Colors.orangeAccent),
                _buildWarrantyStatItem('Expired', '$expired', Colors.redAccent),
              ],
            ),
            if (nextExpiring != null) ...[
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.orangeAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next Expiring:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nextExpiring.productName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${WarrantyUtils.calculateDaysRemaining(nextExpiring.expiryDate)} Days Left',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWarrantyStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
