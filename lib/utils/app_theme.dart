import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Color Constants
  static const Color primaryColor = Color(0xff2e3533);
  static const Color backgroundColor = Color(0xff1b1f1e);
  static const Color accentColor = Color(0xff45c17c);
  static const Color selectionColor = Color(0x6645c17c);
  static const Color dividerColor = Colors.white10;

  // Semantic mappings for hardcoded colors found in analysis
  static const Color textSecondary = Colors.grey;
  static const Color linkColor = Colors.blueAccent;
  static const Color lockedColor = Colors.grey;
  static const Color activeColor = Colors.white;
  static const Color barrierColor = Colors.black87;
  static final Color skeletonColor = Colors.grey.withOpacity(0.3);

  static ThemeData generate(BuildContext context) {
    return ThemeData(
      visualDensity: VisualDensity.compact,

      // Colors
      primaryColor: primaryColor,
      canvasColor: backgroundColor,
      scaffoldBackgroundColor: backgroundColor,
      dividerColor: dividerColor,

      // Color Scheme
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
        outline: Colors.grey.withOpacity(0.2), // For dividers
        error: Colors.redAccent,
      ),

      // Component Themes
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
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: primaryColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      chipTheme: Theme.of(context).chipTheme.copyWith(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        focusElevation: 1,
        highlightElevation: 1,
        foregroundColor: Colors.white,
        backgroundColor: accentColor,
      ),

      iconTheme: const IconThemeData(color: Colors.white),
      primaryIconTheme: const IconThemeData(color: Colors.white),

      popupMenuTheme: PopupMenuThemeData(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
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
