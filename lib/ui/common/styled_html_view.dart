import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/image_loading_error.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/utils/html_styles.dart';
import 'package:octo_image/octo_image.dart';

import 'package:url_launcher/url_launcher.dart';

class StyledHtmlView extends StatefulWidget {
  final String htmlString;
  final int floor;

  const StyledHtmlView(
      {super.key, required this.htmlString, required this.floor});

  @override
  State<StyledHtmlView> createState() => _StyledHtmlViewState();
}

class _StyledHtmlViewState extends State<StyledHtmlView> {
  /// Stable per-view identity for Hero tags (not re-rolled on parent rebuild).
  late final int _randomHash = Random().nextInt(1000);

  @override
  Widget build(BuildContext context) {
    final int cacheWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .toInt();

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(1.0),
      ),
      // Isolate HTML paint from parent chrome (app bar elevation, etc.).
      child: RepaintBoundary(
        child: Html(
          data: widget.htmlString,
          extensions: [
            TagExtension(
              tagsToExtend: {'img'},
              builder: (extensionContext) {
                final src = extensionContext.attributes['src'] ?? '';
                final heroTag = '${widget.floor}_${src}_$_randomHash';
                return _HtmlNetworkImage(
                  src: src,
                  cacheWidth: cacheWidth,
                  heroTag: heroTag,
                  onOpen: () => _showImageView(context, src, heroTag),
                );
              },
            ),
            TagExtension(
              tagsToExtend: {'icon'},
              builder: (extensionContext) {
                final src = extensionContext.attributes['src'] ?? '';
                return Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: OctoImage(
                    image: NetworkImage(src),
                    placeholderBuilder: (context) => const SizedBox(),
                  ),
                );
              },
            ),
          ],
          style: HtmlStyles.generate(context),
          onLinkTap: (url, _, __) => _launchURL(context, url!),
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showImageView(BuildContext context, String url, String heroTag) {
    Navigator.of(context).push(
      FadeRoute(
        page: FullScreenPhotoView(
          heroTag: heroTag,
          url: url,
        ),
      ),
    );
  }
}

/// Image leaf with local error state so a failed load does not rebuild the
/// entire [Html] tree for the comment.
class _HtmlNetworkImage extends StatefulWidget {
  final String src;
  final int cacheWidth;
  final String heroTag;
  final VoidCallback onOpen;

  const _HtmlNetworkImage({
    required this.src,
    required this.cacheWidth,
    required this.heroTag,
    required this.onOpen,
  });

  @override
  State<_HtmlNetworkImage> createState() => _HtmlNetworkImageState();
}

class _HtmlNetworkImageState extends State<_HtmlNetworkImage> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      child: Stack(
        children: [
          OctoImage(
            image: ResizeImage(
              NetworkImage(widget.src),
              width: widget.cacheWidth,
            ),
            placeholderBuilder: (context) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: ProgressSpinner(),
            ),
            errorBuilder: (context, error, stackTrace) {
              // Schedule state update after this frame — avoid setState during build.
              if (!_hasError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _hasError = true);
                  }
                });
              }
              return ImageLoadingError(error.toString());
            },
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hasError ? null : widget.onOpen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
