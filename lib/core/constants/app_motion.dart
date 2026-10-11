import 'package:flutter/animation.dart';

class AppMotion {
  AppMotion._();

  static const Duration press = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 220);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration reveal = Duration(milliseconds: 420);
  static const Duration ambient = Duration(milliseconds: 4200);
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);
}
