import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core backgrounds & surfaces
  static const Color background = Color(0xFF0B1323); // #0b1323
  static const Color backgroundDim = Color(0xFF0B1323);
  static const Color surfaceSecondary = Color(0xFF141A26); // #141a26
  static const Color cardSurface = Color(0xFF1B2333); // #1b2333
  static const Color inputBackground = Color(0xFF060E1D); // #060e1d
  static const Color surfaceVariant = Color(0xFF2D3546); // #2d3546
  static const Color surfaceBright = Color(0xFF31394A); // #31394a

  // Brand accents
  static const Color primary = Color(0xFFADC6FF); // Electric blue / tint #adc6ff
  static const Color onPrimary = Color(0xFF002E6A);
  static const Color primaryContainer = Color(0xFF4D8EFF);
  static const Color onPrimaryContainer = Color(0xFF00285D);

  static const Color secondary = Color(0xFF5DE6FF); // Cyan #5de6ff
  static const Color onSecondary = Color(0xFF00363E);
  static const Color secondaryContainer = Color(0xFF00CBE6);
  static const Color onSecondaryContainer = Color(0xFF00515D);

  static const Color tertiary = Color(0xFF4EDEA3); // Emerald Green #4edea3
  static const Color onTertiary = Color(0xFF003824);
  static const Color tertiaryContainer = Color(0xFF00A572);
  static const Color onTertiaryContainer = Color(0xFF00311F);

  static const Color error = Color(0xFFFFB4AB); // Red #ffb4ab
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Muted variants
  static const Color onSurface = Color(0xFFDBE2F8); // Text primary #dbe2f8
  static const Color onSurfaceVariant = Color(0xFFC2C6D6); // Text secondary #c2c6d6
  static const Color outline = Color(0xFF8C909F); // #8c909f
  static const Color outlineVariant = Color(0xFF424754); // #424754

  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color primaryFixedDim = Color(0xFFADC6FF);
  static const Color onPrimaryFixed = Color(0xFF001A42);
  static const Color onPrimaryFixedVariant = Color(0xFF004395);
  
  static const Color secondaryFixed = Color(0xFFA2EEFF);
  static const Color secondaryFixedDim = Color(0xFF2FD9F4);
  static const Color onSecondaryFixed = Color(0xFF001F25);
  static const Color onSecondaryFixedVariant = Color(0xFF004E5A);

  static const Color tertiaryFixed = Color(0xFF6FFBBE);
  static const Color tertiaryFixedDim = Color(0xFF4EDEA3);
  static const Color onTertiaryFixed = Color(0xFF002113);
  static const Color onTertiaryFixedVariant = Color(0xFF005236);
}

class AppGradients {
  AppGradients._();

  // Blue-Cyan Gradient (Primary buttons)
  static const LinearGradient primaryBlueCyan = LinearGradient(
    colors: [Color(0xFFADC6FF), Color(0xFF5DE6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // AI Gradient (Purple-Magenta)
  static const LinearGradient purpleAI = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Electric Blue-Cyan Accent Gradient
  static const LinearGradient accentBlueCyan = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double base = 8.0;
  static const double xs = 4.0;
  static const double sm = 12.0;
  static const double md = 24.0;
  static const double lg = 40.0;
  static const double xl = 64.0;
  static const double containerMax = 1200.0;
  static const double gutter = 24.0;
}

class AppRadius {
  AppRadius._();

  static const double smVal = 4.0;
  static const double defaultVal = 8.0;
  static const double mdVal = 12.0; // Buttons, inputs
  static const double lgVal = 24.0; // Glass cards

  static final BorderRadius sm = BorderRadius.circular(smVal);
  static final BorderRadius defaultValue = BorderRadius.circular(defaultVal);
  static final BorderRadius md = BorderRadius.circular(mdVal);
  static final BorderRadius lg = BorderRadius.circular(lgVal);
  static final BorderRadius full = BorderRadius.circular(9999.0);
}
