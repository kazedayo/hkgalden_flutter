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
    // Snapshot: replaceWith mutates the live children list during iteration.
    final snapshot = List<Element>.from(elements);
    for (final element in snapshot) {
      if (element.tagName == 'SPAN') {
        // Process nested spans/alignment first (in-place), then transform this span
        // by reparenting already-transformed children — no HTML re-serialization.
        _elementParsing(element.children);
        final transformed = _spanParsing(element);
        if (!identical(transformed, element)) {
          element.replaceWith(transformed);
        }
      } else {
        _applyAlignmentClassIfNeeded(element);
        // Walk non-span children so nested spans (and nested alignment) are processed.
        _elementParsing(element.children);
      }
    }
  }

  /// Maps block alignment `data-nodetype` on P/DIV to CSS class names used by
  /// [HtmlStyles] (`p.center` / `p.right`).
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

  /// Moves all child nodes from [from] into [to] (reparent, no serialization).
  void _moveChildNodes(Element from, Element to) {
    final nodes = List<Node>.from(from.nodes);
    for (final node in nodes) {
      to.append(node);
    }
  }

  /// Builds a simple wrapper element, reparenting [element]'s children into it.
  Element _wrapWithMovedChildren(Element element, Element wrapper) {
    _moveChildNodes(element, wrapper);
    return wrapper;
  }

  Element _spanParsing(Element element) {
    switch (element.getAttribute(GaldenNodeTypes.dataNodetype)) {
      //parse icon
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
      //parse image
      case GaldenNodeTypes.img:
        final src = element.getAttribute(GaldenNodeTypes.dataSrc);
        if (src == null || src.isEmpty) {
          return element;
        }
        return Element.img()
          ..setAttribute(
            'src',
            src,
          );
      //parse link
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
      //parse color
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
      //parse bold
      case GaldenNodeTypes.b:
        return _wrapWithMovedChildren(element, Element.tag('b'));
      //parse italic
      case GaldenNodeTypes.i:
        return _wrapWithMovedChildren(element, Element.tag('i'));
      //parse underline
      case GaldenNodeTypes.u:
        return _wrapWithMovedChildren(element, Element.tag('u'));
      //parse strikethrough
      case GaldenNodeTypes.s:
        return _wrapWithMovedChildren(element, Element.tag('s'));
      //parse center alignment (span form)
      case GaldenNodeTypes.center:
        return _wrapWithMovedChildren(
          element,
          Element.div()..setAttribute('class', GaldenNodeTypes.center),
        );
      //parse right alignment (span form)
      case GaldenNodeTypes.right:
        return _wrapWithMovedChildren(
          element,
          Element.div()..setAttribute('class', GaldenNodeTypes.right),
        );
      //parse h1
      case GaldenNodeTypes.h1:
        return _wrapWithMovedChildren(
          element,
          Element.span()..setAttribute('class', 'h1'),
        );
      //parse h2
      case GaldenNodeTypes.h2:
        return _wrapWithMovedChildren(
          element,
          Element.span()..setAttribute('class', 'h2'),
        );
      //parse h3
      case GaldenNodeTypes.h3:
        return _wrapWithMovedChildren(
          element,
          Element.span()..setAttribute('class', 'h3'),
        );
      default:
        return element;
    }
  }

  /// Builds nested quote HTML for a [reply], walking its parent chain.
  ///
  /// When [includeStartAsQuote] is true (used by [replyWithQuotes]), [reply]
  /// itself is the outermost quoted entry. When false (used by
  /// [commentWithQuotes]), only parents are quoted and [reply]'s body is
  /// appended after the quote chain.
  ///
  /// [isBlocked] when non-null skips/stops at blocked authors. When null, all
  /// authors are included (e.g. [SessionUserUndefined]).
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

    // Collect quote entries closest-first, then reverse for nesting.
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
        // Match prior if-tree: stop walking when a blocked author is hit.
        break;
      }
      chain.add(current);
      current = current.parent;
    }

    if (chain.isEmpty) {
      return body.innerHtml;
    }

    // deepest first for nested open/close structure
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
    // Other states (e.g. loading): body only, no quotes.
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
