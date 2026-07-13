import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/galden_node_types.dart';
import 'package:universal_html/html.dart';
import 'package:universal_html/parsing.dart';

String? parseReplyWithQuotes(Map<String, dynamic> args) =>
    HKGaldenHtmlParser().commentWithQuotes(
        args['reply'] as Reply, args['state'] as SessionUserState);

class HKGaldenHtmlParser {
  static final NodeValidator validator = NodeValidatorBuilder.common()
    ..allowInlineStyles()
    ..allowImages(_AllowAllUriPolicy())
    ..allowNavigation(_AllowAllUriPolicy())
    ..allowCustomElement('p', attributes: ['hex', GaldenNodeTypes.dataNodetype])
    ..allowCustomElement('icon', attributes: ['src'])
    ..allowCustomElement('span', attributes: [
      GaldenNodeTypes.dataNodetype,
      GaldenNodeTypes.dataId,
      GaldenNodeTypes.dataSrc,
      GaldenNodeTypes.dataValue,
      GaldenNodeTypes.dataHref,
      GaldenNodeTypes.dataPackId,
      GaldenNodeTypes.dataSx,
      GaldenNodeTypes.dataSy,
      GaldenNodeTypes.dataAlt,
      'hex'
    ]);

  String? parse(String htmlString) {
    try {
      final htmlDocument = parseHtmlDocument(htmlString);

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
    // replaceWith mutates live children — iterate a snapshot.
    final snapshot = List<Element>.from(elements);
    for (final element in snapshot) {
      if (element.tagName == 'SPAN') {
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
    final tag = element.tagName;
    if (tag != 'P' && tag != 'DIV') {
      return;
    }
    final nodeType = element.getAttribute(GaldenNodeTypes.dataNodetype);
    if (nodeType == GaldenNodeTypes.center ||
        nodeType == GaldenNodeTypes.right) {
      element
        ..setAttribute('class', nodeType!)
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
    switch (element.getAttribute(GaldenNodeTypes.dataNodetype)) {
      case GaldenNodeTypes.smiley:
        final packId = element.getAttribute(GaldenNodeTypes.dataPackId);
        final id = element.getAttribute(GaldenNodeTypes.dataId);
        if (packId == null ||
            packId.isEmpty ||
            id == null ||
            id.isEmpty) {
          return element;
        }
        return Element.tag('icon')
          ..setAttribute(
            'src',
            'https://s.hkgalden.org/smilies/$packId/$id.gif',
          );
      case GaldenNodeTypes.img:
        final src = element.getAttribute(GaldenNodeTypes.dataSrc);
        if (src == null || src.isEmpty) {
          return element;
        }
        final sx = element.getAttribute(GaldenNodeTypes.dataSx);
        final sy = element.getAttribute(GaldenNodeTypes.dataSy);
        final img = Element.img()
          ..setAttribute(
            'src',
            src,
          );
        if (sx != null && sx.isNotEmpty) {
          img.setAttribute(GaldenNodeTypes.dataSx, sx);
        }
        if (sy != null && sy.isNotEmpty) {
          img.setAttribute(GaldenNodeTypes.dataSy, sy);
        }
        return img;
      case GaldenNodeTypes.a:
        final href = element.getAttribute(GaldenNodeTypes.dataHref);
        if (href == null || href.isEmpty) {
          return element;
        }
        final anchor = Element.a()
          ..setAttribute(
            'href',
            href,
          );
        if (element.hasChildNodes()) {
          _moveChildNodes(element, anchor);
        } else {
          anchor.appendText(href);
        }
        return anchor;
      case GaldenNodeTypes.color:
        final value = element.getAttribute(GaldenNodeTypes.dataValue);
        if (value == null || value.isEmpty) {
          return element;
        }
        return _wrapWithMovedChildren(
          element,
          Element.span()
            ..setAttribute('class', 'color')
            ..setAttribute('hex', value),
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
          Element.div()..setAttribute('class', GaldenNodeTypes.center),
        );
      case GaldenNodeTypes.right:
        return _wrapWithMovedChildren(
          element,
          Element.div()..setAttribute('class', GaldenNodeTypes.right),
        );
      case GaldenNodeTypes.h1:
        return _wrapWithMovedChildren(
          element,
          Element.span()..setAttribute('class', 'h1'),
        );
      case GaldenNodeTypes.h2:
        return _wrapWithMovedChildren(
          element,
          Element.span()..setAttribute('class', 'h2'),
        );
      case GaldenNodeTypes.h3:
        return _wrapWithMovedChildren(
          element,
          Element.span()..setAttribute('class', 'h3'),
        );
      default:
        return element;
    }
  }

  String? _buildQuoteChain(
    Reply reply, {
    required bool includeStartAsQuote,
    bool Function(String userId)? isBlocked,
    int maxDepth = 3,
  }) {
    final String baseHtml =
        includeStartAsQuote ? '' : (reply.content ?? '');
    final htmlDoc = parseHtmlDocument(baseHtml);
    final body = htmlDoc.body;
    if (body == null) {
      return includeStartAsQuote ? '' : (reply.content ?? '');
    }

    final List<Reply> chain = <Reply>[];

    if (includeStartAsQuote) {
      if (isBlocked != null && isBlocked(reply.author.userId)) {
        return body.innerHtml;
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
      return body.innerHtml;
    }

    final List<Reply> deepestFirst = chain.reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < deepestFirst.length; i++) {
      buffer.write('<blockquote>');
    }
    for (final quoted in deepestFirst) {
      buffer
        ..write('<div class="quoteName">${quoted.authorNickname} 說:</div>')
        ..write(quoted.content ?? '')
        ..write('</blockquote>');
    }

    if (includeStartAsQuote) {
      body.setInnerHtml(buffer.toString(), validator: validator);
    } else {
      body.setInnerHtml(
        '${buffer.toString()}${body.innerHtml}',
        validator: validator,
      );
    }
    return body.innerHtml;
  }

  String? commentWithQuotes(Reply reply, SessionUserState state) {
    if (state is SessionUserLoaded) {
      return _buildQuoteChain(
        reply,
        includeStartAsQuote: false,
        isBlocked: (userId) =>
            state.sessionUser.blockedUsers.contains(userId),
      );
    }
    if (state is SessionUserUndefined) {
      return _buildQuoteChain(
        reply,
        includeStartAsQuote: false,
      );
    }
    final htmlDoc = parseHtmlDocument(reply.content ?? '');
    return htmlDoc.body?.innerHtml ?? reply.content ?? '';
  }

  String? replyWithQuotes(Reply reply, SessionUserLoaded state) {
    return _buildQuoteChain(
      reply,
      includeStartAsQuote: true,
      isBlocked: (userId) => state.sessionUser.blockedUsers.contains(userId),
    );
  }
}

class _AllowAllUriPolicy implements UriPolicy {
  @override
  bool allowsUri(String uri) {
    return true;
  }
}
