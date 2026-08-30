import 'dart:convert';

import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/galden_node_types.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class HKGaldenHtmlParser {
  String? parse(String htmlString) {
    try {
      final htmlDocument = html_parser.parse(htmlString);

      final body = htmlDocument.body;
      if (body == null) {
        return htmlString;
      }

      final List<Element> childElement = body.children;
      _elementParsing(childElement);
      return body.innerHtml;
    } catch (_) {
      return htmlString;
    }
  }

  void _elementParsing(List<Element> elements) {
    final snapshot = List<Element>.from(elements);
    for (final element in snapshot) {
      if (element.localName == 'span') {
        _elementParsing(element.children);
        final transformed = _spanParsing(element);
        if (!identical(transformed, element)) {
          element.replaceWith(transformed);
        }
      } else {
        _applyAlignmentClassIfNeeded(element);
        _elementParsing(element.children);
      }
    }
  }

  void _applyAlignmentClassIfNeeded(Element element) {
    final tag = element.localName;
    if (tag != 'p' && tag != 'div') {
      return;
    }
    final nodeType = element.attributes[GaldenNodeTypes.dataNodetype];
    if (nodeType == GaldenNodeTypes.center ||
        nodeType == GaldenNodeTypes.right) {
      element
        ..attributes['class'] = nodeType!
        ..attributes.remove(GaldenNodeTypes.dataNodetype);
    }
  }

  void _moveChildNodes(Element from, Element to) {
    final nodes = List<Node>.from(from.nodes);
    for (final node in nodes) {
      to.append(node);
    }
  }

  Element _wrapWithMovedChildren(Element element, Element wrapper) {
    _moveChildNodes(element, wrapper);
    return wrapper;
  }

  Element _spanParsing(Element element) {
    switch (element.attributes[GaldenNodeTypes.dataNodetype]) {
      case GaldenNodeTypes.smiley:
        final packId = element.attributes[GaldenNodeTypes.dataPackId];
        final id = element.attributes[GaldenNodeTypes.dataId];
        if (packId == null || packId.isEmpty || id == null || id.isEmpty) {
          return element;
        }
        return Element.tag('icon')..attributes['src'] =
          'https://s.hkgalden.org/smilies/$packId/$id.gif';
      case GaldenNodeTypes.img:
        final src = element.attributes[GaldenNodeTypes.dataSrc];
        if (src == null || src.isEmpty) {
          return element;
        }
        final sx = element.attributes[GaldenNodeTypes.dataSx];
        final sy = element.attributes[GaldenNodeTypes.dataSy];
        final img = Element.tag('img')..attributes['src'] = src;
        if (sx != null && sx.isNotEmpty) {
          img.attributes[GaldenNodeTypes.dataSx] = sx;
        }
        if (sy != null && sy.isNotEmpty) {
          img.attributes[GaldenNodeTypes.dataSy] = sy;
        }
        return img;
      case GaldenNodeTypes.a:
        final href = element.attributes[GaldenNodeTypes.dataHref];
        if (href == null || href.isEmpty) {
          return element;
        }
        final anchor = Element.tag('a')..attributes['href'] = href;
        if (element.hasChildNodes()) {
          _moveChildNodes(element, anchor);
        } else {
          anchor.append(Text(href));
        }
        return anchor;
      case GaldenNodeTypes.color:
        final value = element.attributes[GaldenNodeTypes.dataValue];
        if (value == null || value.isEmpty) {
          return element;
        }
        return _wrapWithMovedChildren(
          element,
          Element.tag('span')
            ..attributes['class'] = 'color'
            ..attributes['hex'] = value,
        );
      case GaldenNodeTypes.b:
        return _wrapWithMovedChildren(element, Element.tag('b'));
      case GaldenNodeTypes.i:
        return _wrapWithMovedChildren(element, Element.tag('i'));
      case GaldenNodeTypes.u:
        return _wrapWithMovedChildren(element, Element.tag('u'));
      case GaldenNodeTypes.s:
        return _wrapWithMovedChildren(element, Element.tag('s'));
      case GaldenNodeTypes.center:
        return _wrapWithMovedChildren(
          element,
          Element.tag('div')..attributes['class'] = GaldenNodeTypes.center,
        );
      case GaldenNodeTypes.right:
        return _wrapWithMovedChildren(
          element,
          Element.tag('div')..attributes['class'] = GaldenNodeTypes.right,
        );
      case GaldenNodeTypes.h1:
        return _wrapWithMovedChildren(
          element,
          Element.tag('span')..attributes['class'] = 'h1',
        );
      case GaldenNodeTypes.h2:
        return _wrapWithMovedChildren(
          element,
          Element.tag('span')..attributes['class'] = 'h2',
        );
      case GaldenNodeTypes.h3:
        return _wrapWithMovedChildren(
          element,
          Element.tag('span')..attributes['class'] = 'h3',
        );
      default:
        return element;
    }
  }

  String _escapeHtml(String text) {
    return const HtmlEscape(
      HtmlEscapeMode(escapeLtGt: true, escapeQuot: true, escapeApos: true),
    ).convert(text);
  }

  String? _buildQuoteChain(
    Reply reply, {
    required bool includeStartAsQuote,
    bool Function(String userId)? isBlocked,
  }) {
    const int maxDepth = 3;
    final List<Reply> chain = <Reply>[];

    if (includeStartAsQuote) {
      if (isBlocked != null && isBlocked(reply.author.userId)) {
        return '';
      }
      chain.add(reply);
    }

    Reply? current = reply.parent;
    while (current != null && chain.length < maxDepth) {
      if (isBlocked != null && isBlocked(current.author.userId)) {
        break;
      }
      chain.add(current);
      current = current.parent;
    }

    if (chain.isEmpty) {
      return includeStartAsQuote ? '' : (reply.content ?? '');
    }

    final List<Reply> deepestFirst = chain.reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < deepestFirst.length; i++) {
      buffer.write('<blockquote>');
    }
    for (final quoted in deepestFirst) {
      buffer
        ..write(
          '<div class="quoteName">${_escapeHtml(quoted.authorNickname)} 說:</div>',
        )
        ..write(quoted.content ?? '')
        ..write('</blockquote>');
    }

    if (!includeStartAsQuote) {
      buffer.write(reply.content ?? '');
    }
    return buffer.toString();
  }

  String? commentWithQuotes(Reply reply, SessionUserState state) =>
      _buildQuoteChain(
        reply,
        includeStartAsQuote: false,
        isBlocked: state is SessionUserLoaded
            ? (userId) => state.sessionUser.blockedUsers.contains(userId)
            : null,
      );

  String? replyWithQuotes(Reply reply, SessionUserLoaded state) {
    return _buildQuoteChain(
      reply,
      includeStartAsQuote: true,
      isBlocked: (userId) => state.sessionUser.blockedUsers.contains(userId),
    );
  }
}
