import 'package:universal_html/html.dart';
import 'package:universal_html/parsing.dart';

void main() {
  final htmlDocument = parseHtmlDocument('''
  <div><p><span data-nodetype=\"smiley\" data-id=\"SwxOpu8rVQn\" data-pack-id=\"hkg\" data-sx=\"15\" data-sy=\"15\" data-alt=\":)\"></span><span data-nodetype=\"smiley\" data-id=\"SwxOpu8rVQn\" data-pack-id=\"hkg\" data-sx=\"15\" data-sy=\"15\" data-alt=\":)\"></span><span data-nodetype=\"smiley\" data-id=\"SwxOpu8rVQn\" data-pack-id=\"hkg\" data-sx=\"15\" data-sy=\"15\" data-alt=\":)\"></span></p></div>
  ''');

  List<Element> spanElement = htmlDocument.body.querySelectorAll('span');

  for (Element element in spanElement) {
    element.replaceWith(
      Element.img()..setAttribute(
        'src', 'https://s.hkgalden.org/smilies/${element.getAttribute('data-pack-id')}/${element.getAttribute('data-id')}.gif',
      )..setAttribute('width', element.getAttribute('data-sx'))..setAttribute('height', element.getAttribute('data-sy'))
    );
  }

  print(htmlDocument.body.innerHtml);
}
