import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool isLoading;
  final double height;
  final double? width;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient = AppGradients.primaryBlueCyan,
    this.isLoading = false,
    this.height = 54.0,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: disabled ? null : gradient,
        color: disabled ? AppColors.surfaceVariant.withValues(alpha: 0.5) : null,
        borderRadius: AppRadius.md,
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: (gradient == AppGradients.primaryBlueCyan
                          ? AppColors.primary
                          : const Color(0xFF7C4DFF))
                      .withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: AppRadius.md,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.onPrimary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: disabled
                              ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                              : (gradient == AppGradients.primaryBlueCyan
                                  ? AppColors.onPrimary
                                  : Colors.white),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: GoogleFonts.hankenGrotesk(
                          color: disabled
                              ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                              : (gradient == AppGradients.primaryBlueCyan
                                  ? AppColors.onPrimary
                                  : Colors.white),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
