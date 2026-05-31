import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42CC);
  static const Color primaryLight = Color(0xFF9C95FF);
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentGlow = Color(0xFF00FFD1);

  // Background
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color bgCard = Color(0xFF12121A);
  static const Color bgElevated = Color(0xFF1A1A26);
  static const Color bgInput = Color(0xFF1E1E2E);

  // Surface
  static const Color surface = Color(0xFF16162A);
  static const Color surfaceElevated = Color(0xFF1C1C30);

  // Text
  static const Color textPrimary = Color(0xFFEEEEFF);
  static const Color textSecondary = Color(0xFF9090B0);
  static const Color textMuted = Color(0xFF555577);
  static const Color textAccent = Color(0xFF6C63FF);

  // Status
  static const Color online = Color(0xFF00D4AA);
  static const Color away = Color(0xFFFFB020);
  static const Color busy = Color(0xFFFF4466);
  static const Color offline = Color(0xFF555577);

  // Message Bubbles
  static const Color myBubble = Color(0xFF4A42CC);
  static const Color theirBubble = Color(0xFF1C1C30);

  // Divider
  static const Color divider = Color(0xFF22223A);

  // Error / Success
  static const Color error = Color(0xFFFF4466);
  static const Color success = Color(0xFF00D4AA);
  static const Color warning = Color(0xFFFFB020);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF4A42CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00A880)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF0D0D1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppStrings {
  static const String appName = 'Tenku';
  static const String tagline = 'Connect. Create. Belong.';
  static const String tagline2 = 'Where chats become communities.';

  // Auth
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String username = 'Username';
  static const String displayName = 'Display Name';
  static const String bio = 'Bio';

  // Navigation
  static const String home = 'Home';
  static const String chats = 'Chats';
  static const String communities = 'Communities';
  static const String status = 'Status';
  static const String profile = 'Profile';
}

class AppDimensions {
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 28.0;
  static const double radiusFull = 100.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;

  static const double avatarSmall = 36.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 64.0;
  static const double avatarXL = 96.0;

  static const double navBarHeight = 72.0;
  static const double appBarHeight = 60.0;
}
