import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/style.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:url_launcher/url_launcher.dart';

class StyledHtmlView extends StatelessWidget {
  final String htmlString;
  final int floor;

  const StyledHtmlView({Key key, this.htmlString, this.floor})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Html(
        shrinkWrap: true,
        data: htmlString,
        customRender: {
          'img': (context, _, attributes, __) {
            return GestureDetector(
              onTap: () => _showImageView(context.buildContext,
                  attributes['src'], '${floor}_${attributes['src']}'),
              child: Hero(
                tag: '${floor}_${attributes['src']}',
                child: CachedNetworkImage(
                  imageUrl: attributes['src'],
                  placeholder: (context, url) => Container(
                    margin: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  fadeInDuration: Duration(milliseconds: 300),
                  fadeOutDuration: Duration(milliseconds: 300),
                ),
              ),
            );
          },
          'icon': (_, __, attributes, ____) {
            return CachedNetworkImage(
              imageUrl: attributes['src'],
              fadeInDuration: Duration(milliseconds: 300),
              fadeOutDuration: Duration(milliseconds: 300),
            );
          },
          'span': (context, child, attributes, element) {
            if (element.className == ('color')) {
              print('color span detected!');
              Style newStyle = context.style.copyWith(
                  color: Color(int.parse('FF${attributes['hex']}', radix: 16)));
              return ContainerSpan(
                newContext: RenderContext(
                    buildContext: context.buildContext,
                    style: newStyle,
                    parser: context.parser),
                style: newStyle,
                children: (child as ContainerSpan).children,
                child: (child as ContainerSpan).child,
              );
            }
            return child;
          }
        },
        style: {
          "html": Style(
            backgroundColor: Colors.transparent,
            fontSize: FontSize(18),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
          ),
          "body": Style(margin: EdgeInsets.zero, padding: EdgeInsets.zero),
          "a": Style(
              color: Colors.blueAccent, textDecoration: TextDecoration.none),
          "blockquote": Style(
              border: Border(left: BorderSide(color: Colors.grey, width: 2.3)),
              padding: EdgeInsets.only(left: 8),
              margin: EdgeInsets.only(left: 10, right: 0, bottom: 10, top: 15)),
          "div.quoteName":
              Style(fontSize: FontSize.smaller, color: Colors.grey),
          "div.center": Style(alignment: Alignment.center),
          "div.right": Style(alignment: Alignment.centerRight),
          "h1, h2, h3": Style(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
          ),
        },
        onLinkTap: (url) => _launchURL(url),
      );

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: true);
    } else {
      throw 'Could not launch $url';
    }
  }

  _showImageView(BuildContext context, String url, String heroTag) {
    Navigator.of(context).push(
        FadeRoute(page: FullScreenPhotoView(imageUrl: url, heroTag: heroTag)));
  }
}
