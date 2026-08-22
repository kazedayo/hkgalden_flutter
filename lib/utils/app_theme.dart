import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xff2e3533);
  static const Color backgroundColor = Color(0xff1b1f1e);
  static const Color accentColor = Color(0xff45c17c);
  static const Color selectionColor = Color(0x6645c17c);
  static const Color dividerColor = Colors.white10;

  static const Color textSecondary = Colors.grey;
  static const Color linkColor = Colors.blueAccent;
  static const Color lockedColor = Colors.grey;
  static const Color activeColor = Colors.white;
  static const Color barrierColor = Colors.black87;

  static const Color quoteLineColor = Color(0xFF4B5B53);
  static final Color skeletonColor = Colors.grey.withValues(alpha: 0.3);

  /// Corner radius scale — small: chips/inputs/menus, medium: cards/dialogs,
  /// large: modal sheets.
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  /// Slightly lifted fill so link previews read as chips on comment cards.
  /// Solid color only — no elevation/shadows.
  static Color linkPreviewBackground(ColorScheme scheme) => Color.alphaBlend(
        Colors.white.withValues(alpha: 0.10),
        scheme.surface,
      );

  static const BorderSide linkPreviewBorder =
      BorderSide(color: Color(0x28FFFFFF));

  static const BorderRadius linkPreviewRadius =
      BorderRadius.all(Radius.circular(radiusSmall));

  static ThemeData generate(BuildContext context) {
    return ThemeData(
      visualDensity: VisualDensity.compact,

      primaryColor: primaryColor,
      canvasColor: backgroundColor,
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: dividerColor,

      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors
            .grey, // Base for primary, though we override below based on context if needed
        accentColor: accentColor,
        backgroundColor: backgroundColor,
      ).copyWith(
        primary: primaryColor, // Main background for cards/appbars
        onPrimary: Colors.white,
        secondary: accentColor,
        onSecondary: Colors.white,
        surface: primaryColor, // Cards usually use surface
        onSurface: Colors.white,
        onSurfaceVariant: Colors.grey, // For secondary text
        outline: Colors.grey.withValues(alpha: 0.2), // For dividers
        error: Colors.redAccent,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusLarge),
            topRight: Radius.circular(radiusLarge),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: primaryColor,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      chipTheme: Theme.of(context).chipTheme.copyWith(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusSmall)),
          ),

      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: accentColor,
        textTheme: CupertinoTextThemeData(primaryColor: Colors.white),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: primaryColor,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        focusElevation: 1,
        highlightElevation: 1,
        foregroundColor: Colors.white,
        backgroundColor: accentColor,
        shape: CircleBorder(),
      ),

      iconTheme: const IconThemeData(color: Colors.white),
      primaryIconTheme: const IconThemeData(color: Colors.white),

      popupMenuTheme: PopupMenuThemeData(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: accentColor,
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: selectionColor,
        selectionHandleColor: accentColor,
      ),

      textTheme: _buildTextTheme(const TextTheme()),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    const whiteTextStyle = TextStyle(color: Colors.white);
    return base.copyWith(
      displayLarge: whiteTextStyle,
      displayMedium: whiteTextStyle,
      displaySmall: whiteTextStyle,
      headlineLarge: whiteTextStyle,
      headlineMedium: whiteTextStyle,
      headlineSmall: whiteTextStyle,
      titleLarge: whiteTextStyle,
      titleMedium: whiteTextStyle,
      titleSmall: whiteTextStyle,
      bodyLarge: whiteTextStyle,
      bodyMedium: whiteTextStyle,
      bodySmall: whiteTextStyle,
      labelLarge: whiteTextStyle,
      labelMedium: whiteTextStyle,
      labelSmall: whiteTextStyle,
    );
  }
}
