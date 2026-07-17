import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/app/config/theme.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/utils/currency_formatter.dart';

class ReceiptData {
  final String id;
  final String merchant;
  final String date;
  final double amount;
  final String category;
  final IconData icon;
  final String? currency;

  ReceiptData({
    required this.id,
    required this.merchant,
    required this.date,
    required this.amount,
    required this.category,
    required this.icon,
    this.currency,
  });
}

class ReceiptListItem extends StatelessWidget {
  final ReceiptData data;
  final VoidCallback onTap;

  const ReceiptListItem({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isNegative = data.amount < 0;
    final double absoluteAmount = data.amount.abs();
    final String formattedText = '${isNegative ? '-' : ''}${CurrencyFormatter.format(absoluteAmount, currency: data.currency)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: GlassCard(
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Icon + merchant info
              Expanded(
                child: Row(
                  children: [
                    // Merchant icon box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                      ),
                      child: Icon(
                        data.icon,
                        color: AppColors.onSurface,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Merchant & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.merchant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.date,
                            style: textTheme.codeSm.copyWith(
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Right: Amount + category chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedText,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Small category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.full,
                    ),
                    child: Text(
                      data.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
