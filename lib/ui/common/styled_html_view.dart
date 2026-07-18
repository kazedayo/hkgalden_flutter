import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/image_loading_error.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/common/youtube_link_preview.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:hkgalden_flutter/utils/html_styles.dart';
import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';
import 'package:hkgalden_flutter/utils/youtube_url.dart';
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
          MatcherExtension(
            matcher: (extensionContext) {
              if (extensionContext.elementName != 'a') {
                return false;
              }
              final href = extensionContext.attributes['href'];
              return YoutubeUrl.tryParseVideoId(href) != null;
            },
            builder: (extensionContext) {
              final href = extensionContext.attributes['href'] ?? '';
              final videoId = YoutubeUrl.tryParseVideoId(href)!;
              // Keep the original anchor text/URL, preview is additive below.
              final linkLabel = () {
                final text =
                    extensionContext.element?.text.trim() ?? '';
                return text.isNotEmpty ? text : href;
              }();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _launchURL(context, href),
                    // translucent so SelectionArea can still participate in
                    // long-press / drag selection of the link label.
                    behavior: HitTestBehavior.translucent,
                    child: Text(
                      linkLabel,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.linkColor,
                            decoration: TextDecoration.none,
                          ),
                    ),
                  ),
                  YoutubeLinkPreview(
                    href: href,
                    videoId: videoId,
                    onOpen: () => _launchURL(context, href),
                  ),
                ],
              );
            },
          ),
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
        onLinkTap: (url, attributes, element) =>
            _launchURL(context, url!),
      );
      _cachedCacheWidth = cacheWidth;
      _cachedThemeKey = themeKey;
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(1.0),
      ),
      child: SelectionArea(
        // Framework only auto-clears after Copy on Android; always deselect
        // after Copy here. Select All keeps the selection (default behavior).
        contextMenuBuilder: _selectionContextMenuBuilder,
        child: RepaintBoundary(
          child: _cachedHtml!,
        ),
      ),
    );
  }

  /// Builds the selection toolbar; Copy always clears selection afterward.
  static Widget _selectionContextMenuBuilder(
    BuildContext context,
    SelectableRegionState selectableRegionState,
  ) {
    final buttonItems = selectableRegionState.contextMenuButtonItems
        .map((ContextMenuButtonItem item) {
      if (item.type != ContextMenuButtonType.copy) {
        return item;
      }
      return ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: () {
          // Default handler copies to the clipboard (and may partially update
          // UI per platform). Always clear selection afterward.
          item.onPressed?.call();
          selectableRegionState.clearSelection();
          selectableRegionState.hideToolbar();
        },
      );
    }).toList();

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: buttonItems,
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
  /// Decoded pixel aspect (height/width). Never from the reserved layout box.
  double? _decodedAspectRatio;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  ImageProvider _createProvider() {
    return ResizeImage(
      NetworkImage(widget.src),
      width: widget.cacheWidth,
    );
  }

  @override
  void initState() {
    super.initState();
    _listenForDecodedSize();
  }

  @override
  void didUpdateWidget(covariant _HtmlNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src ||
        oldWidget.cacheWidth != widget.cacheWidth) {
      _imageProvider = _createProvider();
      _hasError = false;
      if (oldWidget.src != widget.src) {
        _decodedAspectRatio = null;
      }
      _listenForDecodedSize();
    }
  }

  @override
  void dispose() {
    _stopListeningForDecodedSize();
    super.dispose();
  }

  void _stopListeningForDecodedSize() {
    final stream = _imageStream;
    final listener = _imageStreamListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _listenForDecodedSize() {
    _stopListeningForDecodedSize();
    final stream = _imageProvider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final ratio = ImageAspectRatioStore.aspectRatioFromSize(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        if (ratio == null) {
          return;
        }
        ImageAspectRatioStore.instance.save(widget.src, ratio);
        if (!mounted) {
          return;
        }
        if (_decodedAspectRatio != ratio) {
          setState(() => _decodedAspectRatio = ratio);
        }
      },
      onError: (Object error, StackTrace? stackTrace) {},
    );
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  // Priority: intrinsic attrs → decoded pixels → cache → 3/4 fallback.
  double? _reservedHeight(double maxWidth) {
    if (!maxWidth.isFinite || maxWidth <= 0) {
      return null;
    }
    final sx = widget.intrinsicWidth;
    final sy = widget.intrinsicHeight;
    if (sx != null && sy != null && sx > 0 && sy > 0) {
      return maxWidth * sy / sx;
    }
    final decoded = _decodedAspectRatio;
    if (decoded != null) {
      return maxWidth * decoded;
    }
    final cached =
        ImageAspectRatioStore.instance.aspectRatio(widget.src);
    if (cached != null) {
      return maxWidth * cached;
    }
    return maxWidth * ImageAspectRatioStore.fallbackAspectRatio;
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
        final errorHeight = reservedHeight ?? 80.0;

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
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: ProgressSpinner(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    if (!_hasError) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _hasError = true);
                        }
                      });
                    }
                    return SizedBox(
                      width: maxWidth.isFinite ? maxWidth : null,
                      height: errorHeight,
                      child: Center(
                        child: ImageLoadingError(error.toString()),
                      ),
                    );
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
