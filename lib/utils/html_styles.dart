import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class HtmlStyles {
  static int? _cacheKey;
  static Map<String, Style>? _cached;

  /// Theme-keyed cache so repeated [StyledHtmlView] builds do not reallocate
  /// the full style map when colors/fonts are unchanged.
  static Map<String, Style> generate(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final key = Object.hash(
      theme.brightness,
      colorScheme.onSurface,
      textTheme.bodyLarge?.fontSize,
      AppTheme.quoteLineColor,
      AppTheme.linkColor,
      AppTheme.textSecondary,
    );
    if (_cacheKey == key && _cached != null) {
      return _cached!;
    }

    final styles = <String, Style>{
      "html": Style(
        fontSize:
            FontSize(textTheme.bodyLarge?.fontSize ?? FontSize.large.value),
        color: colorScheme.onSurface,
      ),
      "body": Style(
        margin: Margins.symmetric(vertical: 15),
        padding: HtmlPaddings.zero,
        color: colorScheme.onSurface,
      ),
      "a": Style(
        color: AppTheme.linkColor,
        textDecoration: TextDecoration.none,
      ),
      "blockquote": Style(
        border: Border(
          left: BorderSide(color: AppTheme.quoteLineColor, width: 2.3),
        ),
        padding: HtmlPaddings.only(left: 8),
        margin: Margins.only(left: 10, bottom: 15),
        color: AppTheme.textSecondary,
      ),
      "div.quoteName": Style(
        fontSize: FontSize.smaller,
        color: AppTheme.textSecondary,
        margin: Margins.symmetric(vertical: 4),
      ),
      "span.h1": Style(
        fontSize: FontSize(33),
        fontWeight: FontWeight.normal,
        margin: Margins.zero,
        color: colorScheme.onSurface,
      ),
      "span.h2": Style(
        fontSize: FontSize.xxLarge,
        fontWeight: FontWeight.normal,
        margin: Margins.zero,
        color: colorScheme.onSurface,
      ),
      "span.h3": Style(
        fontSize: FontSize.xLarge,
        fontWeight: FontWeight.normal,
        margin: Margins.zero,
        color: colorScheme.onSurface,
      ),
      "p": Style(
        margin: Margins.zero,
        color: colorScheme.onSurface,
      ),
      "p.center": Style(textAlign: TextAlign.center),
      "p.right": Style(textAlign: TextAlign.right),
      "img": Style(display: Display.inlineBlock),
    };
    _cacheKey = key;
    _cached = styles;
    return styles;
  }

  /// Test hook: clear theme style cache.
  @visibleForTesting
  static void clearCache() {
    _cacheKey = null;
    _cached = null;
  }
}
