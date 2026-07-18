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

// Short fade — OctoImage defaults feel like a full reload after the image viewer.
const Duration _kImageFadeIn = Duration(milliseconds: 150);
const Duration _kImageFadeOut = Duration(milliseconds: 100);

class StyledHtmlView extends StatefulWidget {
  final String htmlString;
  final int floor;

  const StyledHtmlView(
      {super.key, required this.htmlString, required this.floor});

  @override
  State<StyledHtmlView> createState() => _StyledHtmlViewState();
}

class _StyledHtmlViewState extends State<StyledHtmlView> {
  late final int _randomHash = Random().nextInt(1000);
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
              final sx = int.tryParse(
                  extensionContext.attributes['data-sx'] ?? '');
              final sy = int.tryParse(
                  extensionContext.attributes['data-sy'] ?? '');
              final heroTag = '${widget.floor}_${src}_$_randomHash';
              return _HtmlNetworkImage(
                src: src,
                cacheWidth: cacheWidth,
                heroTag: heroTag,
                intrinsicWidth: sx,
                intrinsicHeight: sy,
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
                  fadeInDuration: _kImageFadeIn,
                  fadeOutDuration: _kImageFadeOut,
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

class _HtmlNetworkImage extends StatefulWidget {
  final String src;
  final int cacheWidth;
  final String heroTag;
  final int? intrinsicWidth;
  final int? intrinsicHeight;
  final VoidCallback onOpen;

  const _HtmlNetworkImage({
    required this.src,
    required this.cacheWidth,
    required this.heroTag,
    required this.onOpen,
    this.intrinsicWidth,
    this.intrinsicHeight,
  });

  @override
  State<_HtmlNetworkImage> createState() => _HtmlNetworkImageState();
}

class _HtmlNetworkImageState extends State<_HtmlNetworkImage> {
  bool _hasError = false;

  late ImageProvider _imageProvider = _createProvider();
  // Last laid-out size — avoids collapsing to spinner height on re-decode.
  Size? _lastLayoutSize;

  ImageProvider _createProvider() {
    return ResizeImage(
      NetworkImage(widget.src),
      width: widget.cacheWidth,
    );
  }

  @override
  void didUpdateWidget(covariant _HtmlNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src ||
        oldWidget.cacheWidth != widget.cacheWidth) {
      _imageProvider = _createProvider();
      _hasError = false;
    }
  }

  double? _reservedHeight(double maxWidth) {
    final sx = widget.intrinsicWidth;
    final sy = widget.intrinsicHeight;
    if (sx != null && sy != null && sx > 0 && sy > 0 && maxWidth.isFinite) {
      return maxWidth * sy / sx;
    }
    if (_lastLayoutSize != null &&
        _lastLayoutSize!.width > 0 &&
        maxWidth.isFinite) {
      return maxWidth *
          _lastLayoutSize!.height /
          _lastLayoutSize!.width;
    }
    return null;
  }

  void _rememberSize(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    if (_lastLayoutSize == size) {
      return;
    }
    _lastLayoutSize = size;
  }

  static Widget _heroPlaceholder(
    BuildContext context,
    Size heroSize,
    Widget child,
  ) {
    return SizedBox(
      width: heroSize.width,
      height: heroSize.height,
      child: Offstage(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final reservedHeight = _reservedHeight(maxWidth);

        return Hero(
          tag: widget.heroTag,
          placeholderBuilder: _heroPlaceholder,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                OctoImage(
                  image: _imageProvider,
                  gaplessPlayback: true,
                  fadeInDuration: _kImageFadeIn,
                  fadeOutDuration: _kImageFadeOut,
                  fit: BoxFit.contain,
                  width: maxWidth.isFinite ? maxWidth : null,
                  height: reservedHeight,
                  placeholderBuilder: (context) {
                    if (reservedHeight != null) {
                      return SizedBox(
                        width: maxWidth,
                        height: reservedHeight,
                        child: const Center(child: ProgressSpinner()),
                      );
                    }
                    // No intrinsic size yet — avoid Center (unbounded height in
                    // scrollables). ProgressSpinner stays square on its own.
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: ProgressSpinner(),
                    );
                  },
                  imageBuilder: (context, child) {
                    if (_lastLayoutSize == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) {
                          return;
                        }
                        final box = context.findRenderObject() as RenderBox?;
                        if (box != null && box.hasSize) {
                          _rememberSize(box.size);
                        }
                      });
                    }
                    return child;
                  },
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
          ),
        );
      },
    );
  }
}
