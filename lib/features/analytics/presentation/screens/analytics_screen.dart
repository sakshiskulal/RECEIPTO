import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/features/scan/domain/models/receipt_model.dart';
import 'package:receipto/core/utils/currency_formatter.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(dbReceiptsListProvider);
    final List<Map<String, dynamic>> allRows = receiptsAsync.value ?? [];

    double totalSpending = 0.0;
    double totalSaved = 0.0;
    final Map<String, double> categoryTotals = {};
    final List<double> dayTotals = List.filled(7, 0.0);

    for (final r in allRows) {
      final double amt = ReceiptModel.parseDouble(r['grand_total']) ?? ReceiptModel.parseDouble(r['total']) ?? 0.0;
      final double disc = ReceiptModel.parseDouble(r['discount']) ?? 0.0;
      totalSpending += amt;
      totalSaved += disc;

      final String category = r['category'] as String? ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amt;

      final String? dateStr = r['date'] as String?;
      if (dateStr != null) {
        final parsedDate = DateTime.tryParse(dateStr);
        if (parsedDate != null) {
          dayTotals[parsedDate.weekday - 1] += amt;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background content
          SafeArea(
            bottom: false,
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
                  const SizedBox(height: 24),

                  // Hero Spending Overview
                  _buildHeroSpending(context, totalSpending),
                  const SizedBox(height: 24),

                  // Category Breakdown & Weekly Activity charts
                  _buildChartsSection(context, totalSpending, categoryTotals, dayTotals),
                  const SizedBox(height: 32),

                  // AI Insights & Anomalies Bento Card Grid
                  _buildAIInsightsHeader(context),
                  const SizedBox(height: 16),
                  _buildAIInsightsGrid(context, totalSpending),
                  const SizedBox(height: 32),

                  // Visual Trends Bento Section
                  _buildVisualTrendsHeader(context),
                  const SizedBox(height: 16),
                  _buildVisualTrendsBento(context, totalSaved, allRows.length),

                  // Margin at bottom for FAB & Navbar overlaps
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          
          // FAB
          Positioned(
            bottom: 96,
            right: 20,
            child: _buildFAB(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(firebaseAuthServiceProvider).currentUser;
    final photoURL = user?.photoURL;
    final hasPhoto = photoURL != null && photoURL.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                StatefulNavigationShell.of(context).goBranch(4);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  image: DecorationImage(
                    image: NetworkImage(
                      hasPhoto ? photoURL : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Receipto',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          onPressed: () {},
        ),
      ],
    );
  }

  // Spending Hero Total section
  Widget _buildHeroSpending(BuildContext context, double totalSpending) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Spending',
          style: textTheme.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              CurrencyFormatter.format(totalSpending),
              style: textTheme.displayLg.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                const Icon(
                  Icons.trending_down,
                  color: AppColors.tertiary,
                  size: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  '4.2%',
                  style: textTheme.labelMd.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Charts Grid containing Category Donut & Weekly Activity chart
  Widget _buildChartsSection(
    BuildContext context,
    double totalSpending,
    Map<String, double> categoryTotals,
    List<double> dayTotals,
  ) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final donutCard = _buildDonutChartCard(context, totalSpending, categoryTotals);
    final barChart = _buildWeeklyBarChart(context, dayTotals);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: donutCard),
          const SizedBox(width: 24),
          Expanded(child: barChart),
        ],
      );
    } else {
      return Column(
        children: [
          donutCard,
          const SizedBox(height: 24),
          barChart,
        ],
      );
    }
  }

  Widget _buildDonutChartCard(
    BuildContext context,
    double totalSpending,
    Map<String, double> categoryTotals,
  ) {
    final textTheme = Theme.of(context).textTheme;

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<double> shares = [];
    final List<Color> colors = [
      AppColors.primary,
      AppColors.tertiary,
      AppColors.secondary,
      const Color(0xFF7C4DFF),
      const Color(0xFFFF5252),
      const Color(0xFFFFD740),
    ];
    final List<Widget> legendItems = [];

    int colorIdx = 0;
    for (final entry in sortedCategories) {
      final double share = totalSpending > 0 ? entry.value / totalSpending : 0.0;
      shares.add(share);
      final Color color = colors[colorIdx % colors.length];
      legendItems.add(
        _buildLegendItem(entry.key, CurrencyFormatter.format(entry.value), color),
      );
      colorIdx++;
    }

    if (shares.isEmpty) {
      shares.add(1.0);
      legendItems.add(_buildLegendItem('No data', CurrencyFormatter.format(0.0), AppColors.primary));
    }

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Breakdown',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 32),

          // Donut Chart Graphic
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      shares: shares,
                      colors: colors.take(shares.length).toList(),
                    ),
                  ),
                ),
                // Inner Text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: textTheme.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatCompact(totalSpending),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Legend
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: legendItems.length,
            itemBuilder: (context, idx) => legendItems[idx],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String category, String amount, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: GoogleFonts.inter(
                color: AppColors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Weekly Activity Bar Chart
  Widget _buildWeeklyBarChart(BuildContext context, List<double> dayTotals) {
    final textTheme = Theme.of(context).textTheme;

    double maxTotal = 0.0;
    for (final t in dayTotals) {
      if (t > maxTotal) maxTotal = t;
    }

    final List<double> heights = dayTotals.map((t) => maxTotal > 0 ? t / maxTotal : 0.1).toList();

    int maxIdx = 0;
    double maxVal = -1.0;
    for (int i = 0; i < dayTotals.length; i++) {
      if (dayTotals[i] > maxVal) {
        maxVal = dayTotals[i];
        maxIdx = i;
      }
    }

    final String highlightValue = maxVal > 0 ? CurrencyFormatter.formatCompact(maxVal) : CurrencyFormatter.formatCompact(0.0);

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weekly Activity',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 32),

          // 7-day Bar layout
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDayBar(context, 'M', heights[0], maxIdx == 0 && maxVal > 0, value: maxIdx == 0 && maxVal > 0 ? highlightValue : null),
                _buildDayBar(context, 'T', heights[1], maxIdx == 1 && maxVal > 0, value: maxIdx == 1 && maxVal > 0 ? highlightValue : null),
                _buildDayBar(context, 'W', heights[2], maxIdx == 2 && maxVal > 0, value: maxIdx == 2 && maxVal > 0 ? highlightValue : null),
                _buildDayBar(context, 'T', heights[3], maxIdx == 3 && maxVal > 0, value: maxIdx == 3 && maxVal > 0 ? highlightValue : null),
                _buildDayBar(context, 'F', heights[4], maxIdx == 4 && maxVal > 0, value: maxIdx == 4 && maxVal > 0 ? highlightValue : null),
                _buildDayBar(context, 'S', heights[5], maxIdx == 5 && maxVal > 0, value: maxIdx == 5 && maxVal > 0 ? highlightValue : null),
                _buildDayBar(context, 'S', heights[6], maxIdx == 6 && maxVal > 0, value: maxIdx == 6 && maxVal > 0 ? highlightValue : null),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Divider and summary metrics
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peak Spending Day',
                    style: textTheme.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDayName(maxIdx),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Daily Avg',
                    style: textTheme.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(dayTotals.reduce((a, b) => a + b) / 7),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
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

  String _getDayName(int index) {
    switch (index) {
      case 0: return 'Monday';
      case 1: return 'Tuesday';
      case 2: return 'Wednesday';
      case 3: return 'Thursday';
      case 4: return 'Friday';
      case 5: return 'Saturday';
      case 6: return 'Sunday';
      default: return 'Unknown';
    }
  }

  Widget _buildDayBar(BuildContext context, String day, double heightPercentage, bool isHighlighted, {String? value}) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (value != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: textTheme.labelMd.copyWith(
                color: AppColors.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          width: 22,
          height: 100 * heightPercentage,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: isHighlighted ? AppGradients.primaryBlueCyan : null,
            color: isHighlighted ? null : AppColors.cardSurface.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: GoogleFonts.inter(
            color: isHighlighted ? AppColors.primary : AppColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // AI insights header
  Widget _buildAIInsightsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      'AI Insights & Budget',
      style: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
    );
  }

  // AI Insights grid
  Widget _buildAIInsightsGrid(BuildContext context, double totalSpending) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final limitExceeded = totalSpending > 10000;

    final items = [
      _buildInsightCard(
        title: 'Weekly Budget Target',
        value: limitExceeded ? 'Exceeded limit' : 'On track (target ${CurrencyFormatter.formatCompact(10000.0)})',
        color: limitExceeded ? Colors.redAccent : AppColors.tertiary,
        subtitle: 'Spent ${CurrencyFormatter.formatCompact(totalSpending)} of target',
        icon: Icons.track_changes,
      ),
      _buildInsightCard(
        title: 'Anomalies Detected',
        value: 'None',
        color: AppColors.secondary,
        subtitle: 'Consistent spending habits',
        icon: Icons.security,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: items[0]),
          const SizedBox(width: 16),
          Expanded(child: items[1]),
        ],
      );
    } else {
      return Column(
        children: [
          items[0],
          const SizedBox(height: 16),
          items[1],
        ],
      );
    }
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required Color color,
    required String subtitle,
    required IconData icon,
  }) {
    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      width: double.infinity,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header row for trends section
  Widget _buildVisualTrendsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(
      'Visual Trends',
      style: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
    );
  }

  // Visual Trends bento grid section
  Widget _buildVisualTrendsBento(BuildContext context, double totalSaved, int scannedCount) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final growthCard = _buildBentoGrowthCard(context);
    final travelCard = _buildBentoStatCard(context, 'Total Money Saved', CurrencyFormatter.formatCompact(totalSaved), Icons.savings, AppColors.tertiary);
    final countCard = _buildBentoStatCard(context, 'Receipts Scanned', '$scannedCount', Icons.receipt_long, AppColors.secondary);

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 2, child: growthCard),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: travelCard),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: countCard),
        ],
      );
    } else {
      return Column(
        children: [
          growthCard,
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: travelCard),
              const SizedBox(width: 16),
              Expanded(child: countCard),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildBentoGrowthCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      width: double.infinity,
      height: 160,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Power',
            style: textTheme.labelMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Growth Velocity Index',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStatCard(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.md),
      height: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 36),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
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
              Icons.add,
              color: AppColors.onPrimary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// Donut Chart Custom Painter
class _DonutChartPainter extends CustomPainter {
  final List<double> shares;
  final List<Color> colors;

  _DonutChartPainter({required this.shares, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth);

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < shares.length; i++) {
      final sweepAngle = shares[i] * 2 * math.pi;
      
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Add segment gap simulation (very small offset)
      canvas.drawArc(rect, startAngle + 0.05, sweepAngle - 0.1, false, paint);
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
