import 'package:hkgalden_flutter/bloc/session_user/session_user_state.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:universal_html/parsing.dart';
import 'package:universal_html/html.dart';

class HKGaldenHtmlParser {
  static final NodeValidator validator = NodeValidatorBuilder.common()
    ..allowInlineStyles()
    ..allowImages(_AllowAllUriPolicy())
    ..allowNavigation(_AllowAllUriPolicy())
    ..allowCustomElement('p', attributes: ['hex', 'data-nodetype'])
    ..allowCustomElement('icon', attributes: ['src'])
    ..allowCustomElement('span', attributes: [
      'data-nodetype',
      'data-id',
      'data-src',
      'data-value',
      'data-href',
      'data-pack-id',
      'data-sx',
      'data-sy',
      'data-alt',
      'hex'
    ]);

  String? parse(String htmlString) {
    final htmlDocument = parseHtmlDocument(htmlString.replaceAll(
        'p data-nodetype', 'p class')); //hacky way to parse center / right

    final List<Element> childElement = htmlDocument.body!.children;
    _elementParsing(childElement);
    return htmlDocument.body!.innerHtml;
  }

  void _elementParsing(List<Element> elements) {
    elements.forEach((element) {
      if (element.tagName != 'SPAN') {
        _elementParsing(element.children);
      } else {
        element.replaceWith(_spanParsing(element));
      }
    });
  }

  Element _spanParsing(Element element) {
    switch (element.getAttribute('data-nodetype')) {
      //parse icon
      case 'smiley':
        return Element.tag('icon')
          ..setAttribute(
            'src',
            'https://s.hkgalden.org/smilies/${element.getAttribute('data-pack-id')}/${element.getAttribute('data-id')}.gif',
          );
      //parse image
      case 'img':
        return Element.img()
          ..setAttribute(
            'src',
            element.getAttribute('data-src')!,
          );
      //parse link
      case 'a':
        return Element.a()
          ..setAttribute(
            'href',
            element.getAttribute('data-href')!,
          )
          ..setInnerHtml(element.getAttribute('data-href'),
              validator: validator);
      //parse color
      case 'color':
        return Element.span()
          ..setAttribute('class', 'color')
          ..setAttribute('hex', element.getAttribute('data-value')!)
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      //parse bold
      case 'b':
        return Element.tag('b')
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      //parse italic
      case 'i':
        return Element.tag('i')
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      //parse underline
      case 'u':
        return Element.tag('u')
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      //parse strikethrough
      case 's':
        return Element.tag('s')
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      //parse center alignment
      // case 'center':
      //   return Element.div()
      //     ..setAttribute('class', 'center')
      //     ..setInnerHtml(parse(element.innerHtml), validator: validator);
      //   break;
      //parse right alignment
      // case 'right':
      //   return Element.div()
      //     ..setAttribute('class', 'right')
      //     ..setInnerHtml(parse(element.innerHtml), validator: validator);
      //   break;
      //parse h1
      case 'h1':
        return Element.span()
          ..setAttribute('class', 'h1')
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      //parse h2
      case 'h2':
        return Element.span()
          ..setAttribute('class', 'h2')
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      //parse h3
      case 'h3':
        return Element.span()
          ..setAttribute('class', 'h3')
          ..setInnerHtml(parse(element.innerHtml!), validator: validator);
      default:
        return element;
    }
  }

  //dumb method, may change to recursive function
  String? commentWithQuotes(Reply reply, SessionUserState state) {
    final Reply? rootParent = reply.parent;

    final htmlDoc = parseHtmlDocument(reply.content!);

    //print(htmlDoc.body.children);

    if (rootParent != null &&
        ((state is SessionUserLoaded &&
                !state.sessionUser.blockedUsers
                    .contains(rootParent.author.userId)) ||
            state is SessionUserUndefined)) {
      if (rootParent.parent != null &&
          ((state is SessionUserLoaded &&
                  !state.sessionUser.blockedUsers
                      .contains(rootParent.parent!.author.userId)) ||
              state is SessionUserUndefined)) {
        if (rootParent.parent!.parent != null &&
            ((state is SessionUserLoaded &&
                    !state.sessionUser.blockedUsers
                        .contains(rootParent.parent!.parent!.author.userId)) ||
                state is SessionUserUndefined)) {
          htmlDoc.body!.setInnerHtml('''
                <blockquote style><blockquote><blockquote>
                <div class="quoteName">${rootParent.parent!.parent!.authorNickname} 說:</div>
                ${rootParent.parent!.parent!.content}</blockquote>
                <div class="quoteName">${rootParent.parent!.authorNickname} 說:</div>
                ${rootParent.parent!.content}</blockquote>
                <div class="quoteName">${rootParent.authorNickname} 說:</div>
                ${rootParent.content}</blockquote>${htmlDoc.body!.innerHtml}
              ''', validator: validator);
          //print('result: ${htmlDoc.body.innerHtml}');
          return htmlDoc.body!.innerHtml;
        }
        htmlDoc.body!.setInnerHtml('''
            <blockquote><blockquote>
            <div class="quoteName">${rootParent.parent!.authorNickname} 說:</div>
            ${rootParent.parent!.content}</blockquote>
            <div class="quoteName">${rootParent.authorNickname} 說:</div>
            ${rootParent.content}</blockquote>${htmlDoc.body!.innerHtml}''',
            validator: validator);
        //print('result: ${htmlDoc.body.innerHtml}');
        return htmlDoc.body!.innerHtml;
      }
      htmlDoc.body!.setInnerHtml('''
          <blockquote>
          <div class="quoteName">${rootParent.authorNickname} 說:</div>
          ${rootParent.content}</blockquote>${htmlDoc.body!.innerHtml}''',
          validator: validator);
      //print('result: ${htmlDoc.body.innerHtml}');
      return htmlDoc.body!.innerHtml;
    }
    return htmlDoc.body!.innerHtml;
  }

  String? replyWithQuotes(Reply reply, SessionUserLoaded state) {
    final htmlDoc = parseHtmlDocument('');

    if (!state.sessionUser.blockedUsers.contains(reply.author.userId)) {
      if (reply.parent != null &&
          !state.sessionUser.blockedUsers
              .contains(reply.parent!.author.userId)) {
        if (reply.parent!.parent != null &&
            !state.sessionUser.blockedUsers
                .contains(reply.parent!.parent!.author.userId)) {
          htmlDoc.body!.setInnerHtml('''
            <blockquote style><blockquote><blockquote>
            <div class="quoteName">${reply.parent!.parent!.authorNickname} 說:</div>
            ${reply.parent!.parent!.content}</blockquote>
            <div class="quoteName">${reply.parent!.authorNickname} 說:</div>
            ${reply.parent!.content}</blockquote>
            <div class="quoteName">${reply.authorNickname} 說:</div>
            ${reply.content}</blockquote>${htmlDoc.body!.innerHtml}''',
              validator: validator);
          //print('result: ${htmlDoc.body.innerHtml}');
          return htmlDoc.body!.innerHtml;
        }
        htmlDoc.body!.setInnerHtml('''
              <blockquote><blockquote>
              <div class="quoteName">${reply.parent!.authorNickname} 說:</div>
              ${reply.parent!.content}</blockquote>
              <div class="quoteName">${reply.authorNickname} 說:</div>
              ${reply.content}</blockquote>${htmlDoc.body!.innerHtml}''',
            validator: validator);
        //print('result: ${htmlDoc.body.innerHtml}');
        return htmlDoc.body!.innerHtml;
      }
      htmlDoc.body!.setInnerHtml('''
            <blockquote>
            <div class="quoteName">${reply.authorNickname} 說:</div>
            ${reply.content}</blockquote>${htmlDoc.body!.innerHtml}''',
          validator: validator);
      //print('result: ${htmlDoc.body.innerHtml}');
      return htmlDoc.body!.innerHtml;
    }
    return htmlDoc.body!.innerHtml;
  }
}

class _AllowAllUriPolicy implements UriPolicy {
  @override
  bool allowsUri(String uri) {
    return true;
  }
}
