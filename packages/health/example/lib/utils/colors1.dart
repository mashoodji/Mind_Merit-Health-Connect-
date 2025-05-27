// utils/colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6E48AA);
  static const Color primaryDark = Color(0xFF9D50BB);
  static const Color primaryLight = Color(0xFFF7F8FA);

  // Background Colors
  static const Color background = Color(0xFFF7F8FA);
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textLight = Colors.white;
  static const Color textHint = Colors.grey;

  // Accent Colors
  static const Color accentPurple = Color(0xFF6E48AA);
  static const Color accentRed = Colors.redAccent;
  static const Color accentGreen = Colors.green;
  static const Color accentBlue = Colors.blueAccent;

  // Button Colors
  static const Color buttonPrimary = Color(0xFF6E48AA);
  static const Color buttonSecondary = Colors.white;

  // Chart Colors
  static const Color chartLineRed = Colors.redAccent;
  static const Color chartLineGreen = Colors.green;
  static const Color chartGrid = Color(0xFFE0E0E0);

  // Icon Colors
  static const Color iconPrimary = Colors.deepPurple;
  static const Color iconSecondary = Colors.black54;

  // Gradient
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6E48AA), Color(0xFF9D50BB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // State Colors
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;

  // Other Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x33000000);
}