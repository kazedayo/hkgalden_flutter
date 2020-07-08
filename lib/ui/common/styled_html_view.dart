import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/style.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:url_launcher/url_launcher.dart';

class StyledHtmlView extends StatefulWidget {
  final String htmlString;
  final int floor;

  const StyledHtmlView({Key key, this.htmlString, this.floor})
      : super(key: key);

  @override
  _StyledHtmlViewState createState() => _StyledHtmlViewState();
}

class _StyledHtmlViewState extends State<StyledHtmlView> {
  int _randomHash;

  @override
  void initState() {
    _randomHash = Random().nextInt(1000);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Html(
      data: widget.htmlString,
      customRender: {
        'img': (context, _, attributes, __) {
          return GestureDetector(
              onTap: () => _showImageView(
                  context.buildContext,
                  attributes['src'],
                  '${widget.floor}_${attributes['src']}_$_randomHash'),
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Hero(
                  tag: '${widget.floor}_${attributes['src']}_$_randomHash',
                  child: CachedNetworkImage(
                    imageUrl: attributes['src'],
                    placeholder: (context, url) => SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => SizedBox(
                      width: 25,
                      height: 25,
                      child: Icon(Icons.error),
                    ),
                    fadeInDuration: Duration(milliseconds: 250),
                    fadeOutDuration: Duration(milliseconds: 250),
                  ),
                ),
              ));
        },
        'icon': (_, __, attributes, ____) {
          return Container(
            margin: EdgeInsets.all(3),
            child: CachedNetworkImage(
              alignment: Alignment.center,
              imageUrl: attributes['src'],
              fadeInDuration: Duration(milliseconds: 250),
              fadeOutDuration: Duration(milliseconds: 250),
            ),
          );
        },
        'span': (context, child, attributes, element) {
          if (element.className == ('color')) {
            Style newStyle = context.style.copyWith(
                color: Color(int.parse('FF${attributes['hex']}', radix: 16)),
                fontSize: FontSize(18));
            return Container(
              transform: Matrix4.translationValues(0, 1, 0),
              child: ContainerSpan(
                newContext: RenderContext(
                    buildContext: context.buildContext,
                    style: newStyle,
                    parser: context.parser),
                style: newStyle,
                children: (child as ContainerSpan).children,
                child: (child as ContainerSpan).child,
              ),
            );
          }
          return child;
        }
      },
      style: {
        "html": Style(
          backgroundColor: Colors.transparent,
          fontSize: FontSize(18),
        ),
        "body": Style(
            margin: EdgeInsets.symmetric(vertical: 15, horizontal: 3),
            padding: EdgeInsets.zero),
        "a": Style(
            color: Colors.blueAccent, textDecoration: TextDecoration.none),
        "blockquote": Style(
            border: Border(left: BorderSide(color: Colors.grey, width: 2.3)),
            padding: EdgeInsets.only(left: 8),
            margin: EdgeInsets.only(left: 10, right: 0, bottom: 15, top: 0)),
        "div.quoteName": Style(
            fontSize: FontSize.smaller,
            color: Colors.grey,
            margin: EdgeInsets.symmetric(vertical: 4)),
        "div.center": Style(alignment: Alignment.center),
        "div.right": Style(alignment: Alignment.centerRight),
        "h1, h2, h3": Style(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
        ),
        "p": Style(margin: EdgeInsets.symmetric(vertical: 0)),
      },
      onLinkTap: (url) => _launchURL(url),
    );
  }

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
