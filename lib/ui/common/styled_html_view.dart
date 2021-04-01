import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/html_parser.dart';
import 'package:flutter_html/style.dart';
import 'package:hkgalden_flutter/bloc/cubit/styled_html_view_cubit.dart';
import 'package:hkgalden_flutter/models/ui_state_models/styled_html_view_state.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/image_loading_error.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:octo_image/octo_image.dart';

import 'package:url_launcher/url_launcher.dart';

class StyledHtmlView extends StatelessWidget {
  final String htmlString;
  final int floor;

  const StyledHtmlView(
      {Key? key, required this.htmlString, required this.floor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: BlocProvider(
        create: (context) => StyledHtmlViewCubit(),
        child: BlocBuilder<StyledHtmlViewCubit, StyledHtmlViewState>(
          builder: (context, state) => Html(
            data: htmlString,
            customRender: {
              'img': (context, _, attributes, __) {
                return ContainerSpan(
                  shrinkWrap: true,
                  newContext: context,
                  style: Style(),
                  child: Hero(
                    tag: '${floor}_${attributes['src']}_$state.randomHash',
                    child: Stack(
                      children: [
                        OctoImage(
                          image: NetworkImage(attributes['src']!),
                          placeholderBuilder: (context) => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ProgressSpinner(),
                          ),
                          errorBuilder: (context, error, stackTrace) {
                            BlocProvider.of<StyledHtmlViewCubit>(context)
                                .setImageLoadingHasError(true);
                            return ImageLoadingError(error.toString());
                          },
                        ),
                        Positioned.fill(
                            child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => state.imageLoadingHasError
                                ? null
                                : _showImageView(
                                    context.buildContext,
                                    attributes['src']!,
                                    '${floor}_${attributes['src']}_$state.randomHash',
                                  ),
                          ),
                        ))
                      ],
                    ),
                  ),
                );
              },
              'icon': (context, __, attributes, ____) {
                return ContainerSpan(
                    shrinkWrap: true,
                    newContext: context,
                    style: Style(),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: OctoImage(
                        image: NetworkImage(attributes['src']!),
                        placeholderBuilder: (context) => const SizedBox(),
                      ),
                    ));
              },
              'span': (context, child, attributes, element) {
                if (element!.className == ('color')) {
                  final Style newStyle = context.style.copyWith(
                    color:
                        Color(int.parse('FF${attributes['hex']}', radix: 16)),
                  );
                  return Transform.translate(
                    offset: const Offset(0, 1),
                    child: ContainerSpan(
                      shrinkWrap: true,
                      newContext: RenderContext(
                          buildContext: context.buildContext,
                          style: newStyle,
                          parser: context.parser),
                      style: newStyle,
                      children: (child as ContainerSpan).children,
                      child: child.child,
                    ),
                  );
                }
                return child;
              }
            },
            style: {
              "html": Style(
                fontSize: FontSize.large,
              ),
              "body": Style(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  padding: EdgeInsets.zero),
              "a": Style(
                  color: Colors.blueAccent,
                  textDecoration: TextDecoration.none),
              "blockquote": Style(
                  border: const Border(
                      left: BorderSide(color: Colors.grey, width: 2.3)),
                  padding: const EdgeInsets.only(left: 8),
                  margin: const EdgeInsets.only(left: 10, bottom: 15)),
              "div.quoteName": Style(
                  fontSize: FontSize.smaller,
                  color: Colors.grey,
                  margin: const EdgeInsets.symmetric(vertical: 4)),
              "span.h1": Style(
                fontSize: const FontSize(33),
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
              "p": Style(margin: const EdgeInsets.symmetric()),
              "p.center": Style(textAlign: TextAlign.center),
              "p.right": Style(textAlign: TextAlign.right),
              "img": Style(display: Display.INLINE)
            },
            onLinkTap: (url, _, __, ___) => _launchURL(context, url!),
          ),
        ),
      ),
    );
  }

  // ignore: always_declare_return_types
  Future<void> _launchURL(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url,
          statusBarBrightness: MediaQuery.of(context).platformBrightness);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showImageView(BuildContext context, String url, String heroTag) {
    Navigator.of(context).push(FadeRoute(
        page: FullScreenPhotoView(
      heroTag: heroTag,
      url: url,
    )));
  }
}
