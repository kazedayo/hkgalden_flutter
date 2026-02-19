import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DeltaJsonParser {
  Future<String> toGaldenHtml(List<dynamic> json) async {
    final StringBuffer result = StringBuffer();
    StringBuffer currentRow = StringBuffer();

    for (final element in json) {
      final insert = element['insert'];
      final Map<String, dynamic> attributes =
          element['attributes'] as Map<String, dynamic>? ?? {};

      if (insert is String) {
        // Split by newline to handle interruptions in style
        final parts = insert.split('\n');
        for (int i = 0; i < parts.length; i++) {
          final part = parts[i];
          if (part.isNotEmpty) {
            final styled = await _applyAttributes(part, attributes);
            currentRow.write(styled);
          }

          // If not the last part, we hit a newline
          if (i < parts.length - 1) {
            result.write('<p>$currentRow</p>');
            currentRow.clear();
          }
        }
      } else {
        if (attributes.isNotEmpty) {
          // Pass empty string as placeholder for attribute-based embeds (like images)
          final styled = await _applyAttributes('', attributes);
          currentRow.write(styled);
        }
      }
    }

    // Flush any remaining content in the current row
    if (currentRow.isNotEmpty) {
      result.write('<p>$currentRow</p>');
    }

    return '<div id="pmc">${result.toString().replaceAll('<p></p>', '')}</div>';
  }

  Future<String> _applyAttributes(
      String text, Map<String, dynamic> attributes) async {
    String styled = text;
    for (final entry in attributes.entries) {
      switch (entry.key) {
        case 'a':
          styled =
              '<span data-nodetype="a" data-href="${entry.value}">$styled</span>';
          break;
        case 'b':
          styled = '<span data-nodetype="b">$styled</span>';
          break;
        case 'i':
          styled = '<span data-nodetype="i">$styled</span>';
          break;
        case 'u':
          styled = '<span data-nodetype="u">$styled</span>';
          break;
        case 's':
          styled = '<span data-nodetype="s">$styled</span>';
          break;
        case 'color':
          styled =
              '<span data-nodetype="color" data-value="${entry.value}">$styled</span>';
          break;
        case 'font':
          // Using font attribute for size (h1, h2, h3)
          styled = '<span data-nodetype="${entry.value}">$styled</span>';
          break;
        case 'embed':
          if (entry.value is Map && entry.value['type'] == 'image') {
            final image = await _getImageDimension(entry.value['source']);
            styled =
                '<span data-nodetype="img" data-src="${entry.value['source']}" data-sx="${image.width}" data-sy="${image.height}"></span>';
          }
          break;
      }
    }
    return styled;
  }

  Future<ui.Image> _getImageDimension(String url) {
    final Completer<ui.Image> imageCompleter = Completer<ui.Image>();
    NetworkImage(url)
        .resolve(ImageConfiguration.empty)
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      imageCompleter.complete(info.image);
    }));
    return imageCompleter.future;
  }
}
