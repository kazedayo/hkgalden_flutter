import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/style.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/image_loading_error.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
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
  bool _imageLoadingHasError;

  @override
  void initState() {
    _randomHash = Random().nextInt(1000);
    _imageLoadingHasError = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Html(
        data: widget.htmlString,
        customRender: {
          'img': (context, _, attributes, __) {
            return GestureDetector(
                onTap: () => _imageLoadingHasError
                    ? null
                    : _showImageView(
                        context.buildContext,
                        attributes['src'],
                        '${widget.floor}_${attributes['src']}_$_randomHash',
                      ),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: Hero(
                    tag: '${widget.floor}_${attributes['src']}_$_randomHash',
                    child: CachedNetworkImage(
                      imageUrl: attributes['src'],
                      memCacheWidth: displayWidth(context.buildContext).toInt(),
                      //placeholder: (context, url) => ProgressSpinner(),
                      progressIndicatorBuilder: (context, url, progress) =>
                          ProgressSpinner(
                        value: progress.progress,
                      ),
                      errorWidget: (context, error, stackTrace) {
                        _imageLoadingHasError = true;
                        return ImageLoadingError(error.toString());
                      },
                    ),
                  ),
                ));
          },
          'icon': (context, __, attributes, ____) {
            return Container(
                margin: EdgeInsets.all(3),
                child: CachedNetworkImage(imageUrl: attributes['src']));
          },
          'span': (context, child, attributes, element) {
            if (element.className == ('color')) {
              Style newStyle = context.style.copyWith(
                  color: Color(int.parse('FF${attributes['hex']}', radix: 16)),
                  fontSize: FontSize.large);
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
            fontSize: FontSize.large,
          ),
          "body": Style(
              margin: EdgeInsets.symmetric(vertical: 15),
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
          "span.h1": Style(
            fontSize: FontSize(33),
            fontWeight: FontWeight.normal,
            margin: EdgeInsets.zero,
          ),
          "span.h2": Style(
            fontSize: FontSize.xxLarge,
            fontWeight: FontWeight.normal,
            margin: EdgeInsets.zero,
          ),
          "span.h3": Style(
            fontSize: FontSize.xLarge,
            fontWeight: FontWeight.normal,
            margin: EdgeInsets.zero,
          ),
          "p": Style(margin: EdgeInsets.symmetric(vertical: 0)),
        },
        onLinkTap: (url) => _launchURL(url),
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url,
          statusBarBrightness: MediaQuery.of(context).platformBrightness);
    } else {
      throw 'Could not launch $url';
    }
  }

  _showImageView(BuildContext context, String url, String heroTag) {
    Navigator.of(context).push(FadeRoute(
        page: FullScreenPhotoView(
      heroTag: heroTag,
      url: url,
    )));
  }
}
