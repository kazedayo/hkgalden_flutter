import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/parser/galden_node_types.dart';

/// Escapes characters that are significant in HTML text content.
String _escapeHtmlText(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

/// Escapes characters that are significant in double-quoted HTML attributes.
String _escapeHtmlAttr(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

/// Optional override for resolving remote image pixel size (mainly for tests).
typedef ImageSizeResolver = Future<({int width, int height})> Function(
  String url,
);

class DeltaJsonParser {
  /// Fallback width when image dimensions cannot be resolved in time / at all.
  ///
  /// 800×600 is a common landscape placeholder so Galden HTML always has
  /// numeric `data-sx` / `data-sy` even when the network fails or times out.
  static const int defaultImageWidth = 800;

  /// Fallback height paired with [defaultImageWidth].
  static const int defaultImageHeight = 600;

  static const Duration _imageDimensionTimeout = Duration(seconds: 5);

  final ImageSizeResolver? _imageSizeResolver;

  DeltaJsonParser({ImageSizeResolver? imageSizeResolver})
      : _imageSizeResolver = imageSizeResolver;

  Future<String> toGaldenHtml(List<dynamic> json) async {
    final StringBuffer result = StringBuffer();
    StringBuffer currentRow = StringBuffer();

    for (final element in json) {
      if (element is! Map) continue;
      final Map<String, dynamic> op = Map<String, dynamic>.from(element);

      final insert = op['insert'];
      final attributesRaw = op['attributes'];
      final Map<String, dynamic> attributes = attributesRaw is Map
          ? Map<String, dynamic>.from(attributesRaw)
          : <String, dynamic>{};

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
      } else if (insert != null) {
        // Non-string insert (e.g. embed object): apply attributes if present
        if (attributes.isNotEmpty) {
          final styled = await _applyAttributes('', attributes);
          currentRow.write(styled);
        }
      }
      // Missing insert (null): skip
    }

    // Flush any remaining content in the current row
    if (currentRow.isNotEmpty) {
      result.write('<p>$currentRow</p>');
    }

    return '<div id="pmc">${result.toString().replaceAll('<p></p>', '')}</div>';
  }

  /// Applies Galden style attributes with a fixed wrap order so nesting is
  /// stable regardless of [attributes] map insertion order.
  ///
  /// Wrap strategy: each wrap is `styled = '<span…>$styled</span>'`, so the
  /// **first** applied style is **innermost** and the **last** is **outermost**.
  ///
  /// Fixed order applied INNER → OUTER (resulting DOM outer → inner):
  /// 1. embed (img/smiley) — replaces content when present (innermost)
  /// 2. strikethrough (s)
  /// 3. underline (u)
  /// 4. italic (i)
  /// 5. bold (b)
  /// 6. font/size (h1/h2/h3)
  /// 7. color
  /// 8. link (a) — outermost among styles
  ///
  /// Unknown attribute keys are ignored.
  Future<String> _applyAttributes(
      String text, Map<String, dynamic> attributes) async {
    // Escape user text so raw markup cannot break generated structure.
    String styled = _escapeHtmlText(text);

    // 1. embed — content replacement (innermost when styles also wrap it)
    final embedValue = attributes['embed'];
    if (embedValue is Map) {
      final embed = Map<String, dynamic>.from(embedValue);
      final embedType = embed['type'];
      if (embedType == 'image' && embed['source'] is String) {
        final source = embed['source'] as String;
        final image = await _getImageDimension(source);
        styled =
            '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.img}" ${GaldenNodeTypes.dataSrc}="${_escapeHtmlAttr(source)}" ${GaldenNodeTypes.dataSx}="${image.width}" ${GaldenNodeTypes.dataSy}="${image.height}"></span>';
      } else if (embedType == 'smiley') {
        final smileyHtml = _smileyEmbedToHtml(embed);
        if (smileyHtml != null) {
          styled = smileyHtml;
        }
        // Missing required id/packId: leave [styled] as escaped text (or empty).
      }
    }

    // 2–5. inline marks (inner → outer among themselves: s, u, i, b)
    if (attributes.containsKey(GaldenNodeTypes.s)) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.s}">$styled</span>';
    }
    if (attributes.containsKey(GaldenNodeTypes.u)) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.u}">$styled</span>';
    }
    if (attributes.containsKey(GaldenNodeTypes.i)) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.i}">$styled</span>';
    }
    if (attributes.containsKey(GaldenNodeTypes.b)) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.b}">$styled</span>';
    }

    // 6. font/size (h1, h2, h3)
    final fontValue = attributes['font'];
    if (fontValue is String) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${_escapeHtmlAttr(fontValue)}">$styled</span>';
    }

    // 7. color
    final colorValue = attributes[GaldenNodeTypes.color];
    if (colorValue is String) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.color}" ${GaldenNodeTypes.dataValue}="${_escapeHtmlAttr(colorValue)}">$styled</span>';
    }

    // 8. link (a) — outermost among styles
    final hrefValue = attributes[GaldenNodeTypes.a];
    if (hrefValue is String) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.a}" ${GaldenNodeTypes.dataHref}="${_escapeHtmlAttr(hrefValue)}">$styled</span>';
    }

    return styled;
  }

  /// Builds a Galden smiley span from a Delta embed map, or `null` when
  /// required [id] / [packId] fields are missing.
  ///
  /// Accepts flexible key names so callers can use camelCase, kebab-case, or
  /// the HTML `data-*` attribute names.
  String? _smileyEmbedToHtml(Map<String, dynamic> embed) {
    final id = _readEmbedString(embed, const [
      'id',
      'data-id',
      'smileyId',
    ]);
    final packId = _readEmbedString(embed, const [
      'packId',
      'pack-id',
      'data-pack-id',
    ]);
    if (id == null || packId == null) {
      return null;
    }

    final sx = _readEmbedString(embed, const ['sx', 'data-sx']);
    final sy = _readEmbedString(embed, const ['sy', 'data-sy']);
    final alt = _readEmbedString(embed, const ['alt', 'data-alt']);

    final buffer = StringBuffer()
      ..write('<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.smiley}"')
      ..write(
          ' ${GaldenNodeTypes.dataId}="${_escapeHtmlAttr(id)}"')
      ..write(
          ' ${GaldenNodeTypes.dataPackId}="${_escapeHtmlAttr(packId)}"');
    if (sx != null) {
      buffer.write(' ${GaldenNodeTypes.dataSx}="${_escapeHtmlAttr(sx)}"');
    }
    if (sy != null) {
      buffer.write(' ${GaldenNodeTypes.dataSy}="${_escapeHtmlAttr(sy)}"');
    }
    if (alt != null) {
      buffer.write(' ${GaldenNodeTypes.dataAlt}="${_escapeHtmlAttr(alt)}"');
    }
    buffer.write('></span>');
    return buffer.toString();
  }

  /// Returns the first non-empty string (or stringified number) for [keys].
  static String? _readEmbedString(
    Map<String, dynamic> embed,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = embed[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is num) {
        return value.toString();
      }
    }
    return null;
  }

  /// Resolves image pixel size for [url], never hanging indefinitely.
  ///
  /// Uses an injected [ImageSizeResolver] when provided; otherwise loads via
  /// [NetworkImage] with error + timeout fallbacks to [defaultImageWidth] ×
  /// [defaultImageHeight].
  Future<({int width, int height})> _getImageDimension(String url) async {
    const defaults = (
      width: defaultImageWidth,
      height: defaultImageHeight,
    );
    final resolver = _imageSizeResolver ?? _resolveImageDimensionFromNetwork;
    try {
      // Re-wrap so the Future's reified type is always the record type.
      // A throw-only async resolver is otherwise inferred as Future<Never>,
      // which makes [Future.timeout]'s onTimeout type-check fail at runtime.
      final future = Future<({int width, int height})>(() async {
        return resolver(url);
      });
      return await future.timeout(
        _imageDimensionTimeout,
        onTimeout: () => defaults,
      );
    } catch (_) {
      // Any unexpected failure still yields defaults so compose can proceed.
      return defaults;
    }
  }

  /// Production path: decode via [NetworkImage], complete on success or error.
  Future<({int width, int height})> _resolveImageDimensionFromNetwork(
    String url,
  ) {
    final Completer<({int width, int height})> completer =
        Completer<({int width, int height})>();
    final ImageStream stream =
        NetworkImage(url).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete((
            width: info.image.width,
            height: info.image.height,
          ));
        }
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          // Synthetic defaults so Galden HTML still has data-sx/data-sy.
          completer.complete((
            width: defaultImageWidth,
            height: defaultImageHeight,
          ));
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}
