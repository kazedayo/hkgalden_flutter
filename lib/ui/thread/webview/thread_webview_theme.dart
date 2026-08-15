import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

String colorToCss(Color color) {
  final argb = color.toARGB32();
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  String hex(int v) => v.toRadixString(16).padLeft(2, '0');
  if (a == 255) {
    return '#${hex(r)}${hex(g)}${hex(b)}';
  }
  return 'rgba($r,$g,$b,${(a / 255).toStringAsFixed(3)})';
}

Map<String, String> threadWebViewThemeTokens() {
  final previewBg = AppTheme.linkPreviewBackground(
    const ColorScheme.dark(surface: AppTheme.primaryColor),
  );
  return {
    'bg': colorToCss(AppTheme.backgroundColor),
    'card': colorToCss(AppTheme.primaryColor),
    'on-surface': '#ffffff',
    'text-secondary': colorToCss(AppTheme.textSecondary),
    'link': colorToCss(AppTheme.linkColor),
    'quote': colorToCss(AppTheme.quoteLineColor),
    'brother': '#22c1fe',
    'sister': '#ff7aab',
    'preview-bg': colorToCss(previewBg),
    'preview-border': colorToCss(const Color(0x28FFFFFF)),
    'accent': colorToCss(AppTheme.accentColor),
    'skeleton': colorToCss(AppTheme.skeletonColor),
    'shadow': 'rgba(0,0,0,0.12)',
    'menu-bg': colorToCss(AppTheme.backgroundColor),
  };
}
