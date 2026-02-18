import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class HtmlStyles {
  static Map<String, Style> generate(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return {
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
        color: AppTheme.linkColor, // Or use colorScheme.primary / tertiary
        textDecoration: TextDecoration.none,
      ),
      "blockquote": Style(
        border: Border(
          left: BorderSide(color: AppTheme.textSecondary, width: 2.3),
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
  }
}
