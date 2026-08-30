import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/parser/galden_node_types.dart';

String _escapeHtmlText(String text) {
  return const HtmlEscape(HtmlEscapeMode.element).convert(text);
}

String _escapeHtmlAttr(String value) {
  return const HtmlEscape(HtmlEscapeMode.attribute).convert(value);
}

typedef ImageSizeResolver = Future<({int width, int height})> Function(
  String url,
);

class DeltaJsonParser {
  static const int defaultImageWidth = 800;
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
        final parts = insert.split('\n');
        for (int i = 0; i < parts.length; i++) {
          final part = parts[i];
          if (part.isNotEmpty) {
            final styled = _applyAttributes(part, attributes);
            currentRow.write(styled);
          }

          if (i < parts.length - 1) {
            result.write('<p>$currentRow</p>');
            currentRow.clear();
          }
        }
      } else if (insert is Map) {
        // flutter_quill embed shape: {"insert":{"smiley":{...}}} / {"insert":{"image":"url"}}
        final embedHtml = await _quillEmbedInsertToHtml(
          Map<String, dynamic>.from(insert),
        );
        if (embedHtml != null) {
          currentRow.write(embedHtml);
        }
      } else if (attributes.isNotEmpty) {
        final styled = _applyAttributes('', attributes);
        currentRow.write(styled);
      }
    }

    if (currentRow.isNotEmpty) {
      result.write('<p>$currentRow</p>');
    }

    return '<div id="pmc">${result.toString().replaceAll('<p></p>', '')}</div>';
  }

  String _applyAttributes(String text, Map<String, dynamic> attributes) {
    String styled = _escapeHtmlText(text);

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

    final fontValue = attributes['font'];
    if (fontValue is String) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${_escapeHtmlAttr(fontValue)}">$styled</span>';
    }

    final colorValue = attributes[GaldenNodeTypes.color];
    if (colorValue is String) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.color}" ${GaldenNodeTypes.dataValue}="${_escapeHtmlAttr(colorValue)}">$styled</span>';
    }

    final hrefValue = attributes[GaldenNodeTypes.a];
    if (hrefValue is String) {
      styled =
          '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.a}" ${GaldenNodeTypes.dataHref}="${_escapeHtmlAttr(hrefValue)}">$styled</span>';
    }

    return styled;
  }

  /// Handles flutter_quill native embed inserts (`{"smiley":...}` / `{"image":...}`).
  Future<String?> _quillEmbedInsertToHtml(Map<String, dynamic> insert) async {
    final smileyValue = insert['smiley'];
    if (smileyValue is Map) {
      return _smileyEmbedToHtml(Map<String, dynamic>.from(smileyValue));
    }

    final imageValue = insert['image'];
    if (imageValue is String && imageValue.isNotEmpty) {
      final image = await _getImageDimension(imageValue);
      return '<span ${GaldenNodeTypes.dataNodetype}="${GaldenNodeTypes.img}" '
          '${GaldenNodeTypes.dataSrc}="${_escapeHtmlAttr(imageValue)}" '
          '${GaldenNodeTypes.dataSx}="${image.width}" '
          '${GaldenNodeTypes.dataSy}="${image.height}"></span>';
    }

    return null;
  }

  String? _smileyEmbedToHtml(Map<String, dynamic> embed) {
    final id = _readEmbedString(embed, 'id');
    final packId = _readEmbedString(embed, 'packId');
    if (id == null || packId == null) {
      return null;
    }

    final sx = _readEmbedString(embed, 'width');
    final sy = _readEmbedString(embed, 'height');
    final alt = _readEmbedString(embed, 'alt');

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

  static String? _readEmbedString(Map<String, dynamic> embed, String key) {
    final value = embed[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }

  Future<({int width, int height})> _getImageDimension(String url) async {
    const defaults = (
      width: defaultImageWidth,
      height: defaultImageHeight,
    );
    final resolver = _imageSizeResolver ?? _resolveImageDimensionFromNetwork;
    try {
      // Re-wrap so timeout typing is Future<({int,int})>, not Future<Never>.
      final future = Future<({int width, int height})>(() async {
        return resolver(url);
      });
      return await future.timeout(
        _imageDimensionTimeout,
        onTimeout: () => defaults,
      );
    } catch (_) {
      return defaults;
    }
  }

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
