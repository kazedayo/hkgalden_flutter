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

  /// Memoized [Html] subtree — reused when content/layout/theme inputs match.
  Widget? _cachedHtml;
  int? _cachedCacheWidth;
  int? _cachedThemeKey;

  @override
  void didUpdateWidget(covariant StyledHtmlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.htmlString != oldWidget.htmlString ||
        widget.floor != oldWidget.floor) {
      _cachedHtml = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int cacheWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .toInt();
    final theme = Theme.of(context);
    final int themeKey =
        Object.hash(theme.brightness, theme.colorScheme.onSurface);

    // Do not reuse across rotation (cacheWidth) or theme flips.
    if (_cachedHtml == null ||
        _cachedCacheWidth != cacheWidth ||
        _cachedThemeKey != themeKey) {
      _cachedHtml = Html(
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
              final dpr = MediaQuery.devicePixelRatioOf(context);
              final cachePx = (48 * dpr).round();
              return Padding(
                padding: const EdgeInsets.all(3.0),
                child: OctoImage(
                  image: ResizeImage(
                    NetworkImage(src),
                    width: cachePx,
                    height: cachePx,
                  ),
                  gaplessPlayback: true,
                  placeholderBuilder: (context) => const SizedBox(),
                ),
              );
            },
          ),
        ],
        style: HtmlStyles.generate(context),
        onLinkTap: (url, _, __) => _launchURL(context, url!),
      );
      _cachedCacheWidth = cacheWidth;
      _cachedThemeKey = themeKey;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(1.0),
      ),
      child: RepaintBoundary(
        child: _cachedHtml!,
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
            gaplessPlayback: true,
            placeholderBuilder: (context) => const Padding(
              padding: EdgeInsets.all(8.0),
              child: ProgressSpinner(),
            ),
            errorBuilder: (context, error, stackTrace) {
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
