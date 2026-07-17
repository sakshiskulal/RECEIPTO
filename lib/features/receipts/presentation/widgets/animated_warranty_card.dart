import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/utils/warranty_utils.dart';
import 'package:receipto/features/warranty/domain/models/warranty_model.dart';

class AnimatedWarrantyCard extends StatefulWidget {
  final WarrantyModel warranty;

  const AnimatedWarrantyCard({
    super.key,
    required this.warranty,
  });

  @override
  State<AnimatedWarrantyCard> createState() => _AnimatedWarrantyCardState();
}

class _AnimatedWarrantyCardState extends State<AnimatedWarrantyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Color rules: Green (Healthy), Orange (Expiring Soon), Red (Expired)
  Color _resolveStatusColor(int daysRemaining, String status) {
    final s = status.toUpperCase().replaceAll('_', ' ');
    if (daysRemaining < 0 || s.contains('EXPIRED')) {
      return const Color(0xFFEF4444); // Red
    } else if (daysRemaining <= 30 || s.contains('EXPIRING')) {
      return const Color(0xFFF59E0B); // Orange / Amber
    } else {
      return const Color(0xFF10B981); // Green
    }
  }

  String _getWarrantyTypeBadge(int period, String unit) {
    final u = unit.toLowerCase();
    int months = period;
    if (u.contains('year')) months = period * 12;
    if (months > 12) {
      return 'Extended Warranty';
    }
    return 'Manufacturer Warranty';
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.warranty;
    final daysRemaining = WarrantyUtils.calculateDaysRemaining(w.expiryDate);
    final totalDays = WarrantyUtils.calculateTotalDays(w.warrantyPeriod, w.warrantyUnit);
    final double progressRatio = totalDays > 0 ? (daysRemaining / totalDays).clamp(0.0, 1.0) : 0.0;

    final Color statusColor = _resolveStatusColor(daysRemaining, w.status);
    final String typeSubtitle = _getWarrantyTypeBadge(w.warrantyPeriod, w.warrantyUnit);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14.0),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.lg,
            child: Stack(
              children: [
                // Left Color Accent Strip
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3.5,
                    color: statusColor,
                  ),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Shield Icon, Product Name, Subtitle & Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0, right: 8.0),
                            child: Icon(
                              Icons.shield_outlined,
                              color: statusColor,
                              size: 18,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.productName,
                                  style: GoogleFonts.hankenGrotesk(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  typeSubtitle,
                                  style: GoogleFonts.inter(
                                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Premium Rounded Status Chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Text(
                              w.status.toUpperCase().replaceAll('_', ' '),
                              style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Restored Explicit Information Rows
                      _buildWarrantyDataRow('Warranty Duration', '${w.warrantyPeriod} ${w.warrantyUnit}'),
                      if (w.purchaseDate.isNotEmpty)
                        _buildWarrantyDataRow('Purchase Date', w.purchaseDate),
                      _buildWarrantyDataRow('Expiration Date', w.expiryDate),
                      _buildWarrantyDataRow(
                        'Days Remaining',
                        daysRemaining >= 0 ? '$daysRemaining Days' : 'Expired',
                        valueColor: statusColor,
                        isBold: true,
                      ),

                      const SizedBox(height: 10),

                      // Thin Warranty Progress Bar (4.5px height)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(
                              height: 4.5,
                              width: double.infinity,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            FractionallySizedBox(
                              widthFactor: progressRatio,
                              child: Container(
                                height: 4.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusColor.withValues(alpha: 0.6),
                                      statusColor,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                      const SizedBox(height: 8),

                      // Bottom Right Action Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            context.push('/receipts/warranty/${w.id}');
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Warranty Details',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarrantyDataRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: valueColor ?? AppColors.onSurface,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
