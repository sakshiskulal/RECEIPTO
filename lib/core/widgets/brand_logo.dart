import 'package:flutter/material.dart';
import 'package:receipto/core/constants/constants.dart';

class BrandLogoIcon extends StatelessWidget {
  final double size;

  const BrandLogoIcon({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: AppGradients.accentBlueCyan,
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White letter shape matching D-shape in SVG
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.05),
                bottomLeft: Radius.circular(size * 0.05),
                topRight: Radius.circular(size * 0.25),
                bottomRight: Radius.circular(size * 0.25),
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2.0),
                  bottomLeft: Radius.circular(2.0),
                  topRight: Radius.circular(13.0),
                  bottomRight: Radius.circular(13.0),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(size * 0.13),
                  bottomRight: Radius.circular(size * 0.13),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppGradients.accentBlueCyan,
                  ),
                ),
              ),
            ),
          ),
          // Cross hair markings in SVG bottom right
          Positioned(
            bottom: size * 0.1,
            right: size * 0.1,
            child: Icon(
              Icons.close_sharp,
              size: size * 0.15,
              color: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
}
