import 'package:hkgalden_flutter/models/reply.dart';
import 'package:universal_html/parsing.dart';
import 'package:universal_html/html.dart';

class HKGaldenHtmlParser {
  String parse(String htmlString) {
    final htmlDocument = parseHtmlDocument(htmlString);

    List<Element> spanElement = htmlDocument.body.querySelectorAll('span');
    for (Element element in spanElement) {
      switch (element.getAttribute('data-nodetype')) {
        //parse icon
        case 'smiley':
          element.replaceWith(
            Element.img()..setAttribute(
              'src', 'https://s.hkgalden.org/smilies/${element.getAttribute('data-pack-id')}/${element.getAttribute('data-id')}.gif',
            )..setAttribute('width', element.getAttribute('data-sx'))..setAttribute('height', element.getAttribute('data-sy'))
          );
          break;
        //parse image
        case 'img':
          element.replaceWith(
            Element.img()..setAttribute(
              'src', element.getAttribute('data-src'),
            )
          );
          break;
        //parse link
        case 'a': 
          element.replaceWith(
            Element.a()..setAttribute(
              'href', element.getAttribute('data-href'),
            )..setInnerHtml(element.getAttribute('data-href'))
          );
          break;
        default:
      }
    }

    return htmlDocument.body.innerHtml;
  }

  //dumb method, may change to recursive function
  String commentWithQuotes(Reply reply) {
    final Reply rootParent = reply.parent;
    NodeValidator validator = NodeValidatorBuilder.common()..allowImages(_AllowAllUriPolicy())..allowNavigation(_AllowAllUriPolicy());

    final htmlDoc = parseHtmlDocument(reply.content);

    if (rootParent != null) {
      if (rootParent.parent != null) {
        if (rootParent.parent.parent != null) {
          htmlDoc.body.setInnerHtml('<blockquote><blockquote><blockquote>${rootParent.parent.parent.content}</blockquote>${rootParent.parent.content}</blockquote>${rootParent.content}</blockquote>${htmlDoc.body.innerHtml}', validator: validator);
        return htmlDoc.body.innerHtml;
        }
        htmlDoc.body.setInnerHtml('<blockquote><blockquote>${rootParent.parent.content}</blockquote>${rootParent.content}</blockquote>${htmlDoc.body.innerHtml}', validator: validator);
        return htmlDoc.body.innerHtml;
      }
      htmlDoc.body.setInnerHtml('<blockquote>${rootParent.content}</blockquote>${htmlDoc.body.innerHtml}', validator: validator);
      return htmlDoc.body.innerHtml;
    }
    return htmlDoc.body.innerHtml;
  }
}

class _AllowAllUriPolicy implements UriPolicy {
  bool allowsUri(String uri) {
    return true;
  }
}