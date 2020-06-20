import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:universal_html/parsing.dart';
import 'package:universal_html/html.dart';

class HKGaldenHtmlParser {
  static final NodeValidator validator = NodeValidatorBuilder.common()
      ..allowImages(_AllowAllUriPolicy())
      ..allowNavigation(_AllowAllUriPolicy())
      ..allowCustomElement('color', attributes: ['hex'])
      ..allowCustomElement('icon', attributes: ['src']);

  String parse(String htmlString) {
    final htmlDocument = parseHtmlDocument(htmlString);

    List<Element> spanElement = htmlDocument.body.querySelectorAll('span');
    for (Element element in spanElement) {
      switch (element.getAttribute('data-nodetype')) {
        //parse icon
        case 'smiley':
          element.replaceWith(
            Element.tag('icon')..setAttribute(
              'src', 'https://s.hkgalden.org/smilies/${element.getAttribute('data-pack-id')}/${element.getAttribute('data-id')}.gif',
            )
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
        //parse color
        case 'color': 
          element.replaceWith(
            Element.html('<color hex="${element.getAttribute('data-value')}">${element.text}</color>', validator: validator)
          );
          break;
        //parse strikethrough
        case 's':
          element.replaceWith(
            Element.tag('s')..setInnerHtml(element.text)
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

    final htmlDoc = parseHtmlDocument(reply.content);

    if (rootParent != null && !store.state.sessionUserState.sessionUser.blockedUsers.contains(rootParent.author.userId)) {
      if (rootParent.parent != null && !store.state.sessionUserState.sessionUser.blockedUsers.contains(rootParent.parent.author.userId)) {
        if (rootParent.parent.parent != null && !store.state.sessionUserState.sessionUser.blockedUsers.contains(rootParent.parent.parent.author.userId)) {
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