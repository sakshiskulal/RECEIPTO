import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class SparklineWidget extends StatelessWidget {
  final List<double> heights;

  const SparklineWidget({
    super.key,
    required this.heights,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights.asMap().entries.map((entry) {
        final index = entry.key;
        final heightPercentage = entry.value;
        final isLast = index == heights.length - 1;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              height: heightPercentage * 64,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
                color: isLast
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.15 + (index * 0.08)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
