import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing and Padding
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radii
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;

  // Box Spacers
  static const SizedBox hXS = SizedBox(height: xs);
  static const SizedBox hSM = SizedBox(height: sm);
  static const SizedBox hMD = SizedBox(height: md);
  static const SizedBox hLG = SizedBox(height: lg);
  static const SizedBox hXL = SizedBox(height: xl);
  static const SizedBox hXXL = SizedBox(height: xxl);

  static const SizedBox wXS = SizedBox(width: xs);
  static const SizedBox wSM = SizedBox(width: sm);
  static const SizedBox wMD = SizedBox(width: md);
  static const SizedBox wLG = SizedBox(width: lg);
  static const SizedBox wXL = SizedBox(width: xl);
}
