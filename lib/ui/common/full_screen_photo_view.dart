import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenPhotoView extends StatefulWidget {
  final String? url;

  final int? intrinsicWidth;
  final int? intrinsicHeight;

  const FullScreenPhotoView({
    super.key,
    this.url,
    this.intrinsicWidth,
    this.intrinsicHeight,
  });

  static Future<void> open(
    BuildContext context, {
    required String url,
    int? intrinsicWidth,
    int? intrinsicHeight,
  }) {
    return Navigator.of(context).push<void>(
      _PhotoViewRoute(
        builder: (context) => FullScreenPhotoView(
          url: url,
          intrinsicWidth: intrinsicWidth,
          intrinsicHeight: intrinsicHeight,
        ),
      ),
    );
  }

  @override
  State<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView>
    with TickerProviderStateMixin {
  static const _minScale = 1.0;
  static const _maxScale = 3.0;
  static const _midScale = 2.0;
  static const _dismissDistance = 140.0;
  static const _dismissVelocity = 700.0;

  Size? _naturalSize;

  ImageStream? _sizeStream;
  ImageStreamListener? _sizeListener;

  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _zoomController;
  late final AnimationController _dismissController;
  Animation<Matrix4>? _zoomAnimation;
  Animation<double>? _dismissAnimation;

  Offset? _doubleTapPosition;
  double _scale = 1.0;
  double _dismissOffset = 0;
  int _activePointers = 0;
  Offset? _dismissPointerStart;
  VelocityTracker? _dismissVelocityTracker;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_applyZoomAnimation);
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(_applyDismissAnimation);
    _naturalSize = _sizeFromAttrsOrCache();
    if (_naturalSize == null) {
      _listenForNaturalSize();
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _dismissController.dispose();
    _transformationController.dispose();
    _stopSizeListener();
    super.dispose();
  }

  bool get _isZoomed => _scale > 1.05;

  void _applyZoomAnimation() {
    final animation = _zoomAnimation;
    if (animation == null) {
      return;
    }
    _transformationController.value = animation.value;
  }

  void _applyDismissAnimation() {
    final animation = _dismissAnimation;
    if (animation == null || !mounted) {
      return;
    }
    setState(() => _dismissOffset = animation.value);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  double _nextDoubleTapScale() {
    if (_scale + 0.1 < _midScale) {
      return _midScale;
    }
    if (_scale + 0.1 < _maxScale) {
      return _maxScale;
    }
    return _minScale;
  }

  Matrix4 _matrixForScale(double scale, Offset tap) {
    if (scale <= _minScale + 0.01) {
      return Matrix4.identity();
    }
    return Matrix4.identity()
      ..translate(-tap.dx * (scale - 1), -tap.dy * (scale - 1))
      ..scale(scale);
  }

  void _toggleZoom() {
    final tap = _doubleTapPosition;
    if (tap == null) {
      return;
    }

    final end = _matrixForScale(_nextDoubleTapScale(), tap);

    _zoomAnimation =
        Matrix4Tween(begin: _transformationController.value, end: end).animate(
          CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic),
        );
    _zoomController.forward(from: 0).whenComplete(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _scale = _transformationController.value.getMaxScaleOnAxis();
      });
    });
  }

  void _syncScaleFromTransform() {
    final next = _transformationController.value.getMaxScaleOnAxis();
    if ((next - _scale).abs() < 0.001) {
      return;
    }
    setState(() => _scale = next);
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _zoomController.stop();
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    _syncScaleFromTransform();
  }

  bool _canSwipeDismiss(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS && !_isZoomed;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers > 1) {
      _dismissPointerStart = null;
      _dismissVelocityTracker = null;
      if (_dismissOffset != 0) {
        _snapDismissBack();
      }
      return;
    }
    if (!_canSwipeDismiss(context)) {
      return;
    }
    _dismissController.stop();
    _dismissPointerStart = event.position;
    _dismissVelocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final start = _dismissPointerStart;
    final tracker = _dismissVelocityTracker;
    if (start == null || tracker == null || _activePointers != 1) {
      return;
    }
    if (!_canSwipeDismiss(context)) {
      return;
    }
    tracker.addPosition(event.timeStamp, event.position);
    setState(() {
      _dismissOffset = math.max(0, event.position.dy - start.dy);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = math.max(0, _activePointers - 1);
    if (_activePointers != 0) {
      return;
    }
    _finishDismissGesture();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = math.max(0, _activePointers - 1);
    if (_activePointers == 0) {
      _finishDismissGesture();
    }
  }

  void _finishDismissGesture() {
    _dismissPointerStart = null;
    final velocity =
        _dismissVelocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0;
    _dismissVelocityTracker = null;
    if (_dismissOffset == 0) {
      return;
    }
    if (_dismissOffset >= _dismissDistance || velocity >= _dismissVelocity) {
      _commitDismiss();
      return;
    }
    _snapDismissBack();
  }

  void _commitDismiss() {
    _dismissPointerStart = null;
    _dismissVelocityTracker = null;
    _dismissController.stop();
    final end = MediaQuery.sizeOf(context).height;
    if (end - _dismissOffset < 1) {
      Navigator.of(context).pop();
      return;
    }
    _dismissAnimation = Tween<double>(begin: _dismissOffset, end: end).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOut),
    );
    _dismissController.forward(from: 0).whenComplete(() {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _snapDismissBack() {
    _dismissPointerStart = null;
    _dismissVelocityTracker = null;
    if (_dismissOffset == 0) {
      return;
    }
    _dismissAnimation = Tween<double>(begin: _dismissOffset, end: 0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOut),
    );
    _dismissController.forward(from: 0);
  }

  Size? _sizeFromAttrsOrCache() {
    final sx = widget.intrinsicWidth;
    final sy = widget.intrinsicHeight;
    if (sx != null && sy != null && sx > 0 && sy > 0) {
      return Size(sx.toDouble(), sy.toDouble());
    }

    final url = widget.url;
    if (url == null || url.isEmpty) {
      return null;
    }

    final cachedW = ImageAspectRatioStore.instance.naturalWidth(url);
    final ratio = ImageAspectRatioStore.instance.aspectRatio(url);

    if (sx != null && sx > 0) {
      final r =
          ratio ??
          (sy != null && sy > 0 ? sy / sx : null) ??
          ImageAspectRatioStore.fallbackAspectRatio;
      return Size(sx.toDouble(), sx * r);
    }
    if (cachedW != null) {
      final r = ratio ?? ImageAspectRatioStore.fallbackAspectRatio;
      return Size(cachedW, cachedW * r);
    }
    return null;
  }

  void _stopSizeListener() {
    final stream = _sizeStream;
    final listener = _sizeListener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _sizeStream = null;
    _sizeListener = null;
  }

  void _listenForNaturalSize() {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      return;
    }
    _stopSizeListener();
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        final ratio = ImageAspectRatioStore.aspectRatioFromSize(w, h);
        if (ratio != null) {
          ImageAspectRatioStore.instance.save(url, ratio, naturalWidth: w);
        }
        if (!mounted) {
          return;
        }
        final next = Size(w, h);
        if (_naturalSize != next) {
          setState(() => _naturalSize = next);
        }
        _stopSizeListener();
      },
      onError: (Object error, StackTrace? stackTrace) {
        _stopSizeListener();
      },
    );
    _sizeStream = stream;
    _sizeListener = listener;
    stream.addListener(listener);
  }

  Size? _displaySize(BuildContext context) {
    final natural = _naturalSize;
    if (natural == null || natural.width <= 0 || natural.height <= 0) {
      return null;
    }

    final maxW = MediaQuery.sizeOf(context).width;
    final maxH = MediaQuery.sizeOf(context).height;
    var w = natural.width;
    var h = natural.height;
    if (w > maxW) {
      h = h * maxW / w;
      w = maxW;
    }
    if (h > maxH) {
      w = w * maxH / h;
      h = maxH;
    }
    return Size(w, h);
  }

  int _decodeWidth(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final screenCap = math.max(1, (MediaQuery.sizeOf(context).width * dpr).round());
    final natural = _naturalSize;
    if (natural == null) {
      return screenCap;
    }
    final naturalCap = math.max(1, (natural.width * dpr).round());
    return math.min(screenCap, naturalCap);
  }

  ImageProvider _imageProvider(BuildContext context) {
    final network = NetworkImage(widget.url!);
    final natural = _naturalSize;
    if (natural == null) {
      return network;
    }
    return ResizeImage(network, width: _decodeWidth(context));
  }

  static Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareImage(String url, {Rect? sharePositionOrigin}) async {
    setState(() => _sharing = true);
    String? filePath;
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _fileNameFor(url);
      filePath = '${tempDir.path}/$fileName';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('download failed');
      }
      await File(filePath).writeAsBytes(response.bodyBytes);
      if (!mounted) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: _mimeTypeFor(fileName))],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (mounted) {
        setState(() => _sharing = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法分享圖片')),
        );
      }
    } finally {
      final path = filePath;
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }
  }

  static String _fileNameFor(String url) {
    final uri = Uri.tryParse(url);
    var name = (uri != null && uri.pathSegments.isNotEmpty)
        ? uri.pathSegments.last
        : url.split('/').last;
    name = name.split('?').first;
    if (name.isEmpty || !name.contains('.')) {
      return 'image.jpg';
    }
    return name;
  }

  static String _mimeTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.url!;
    final display = _displaySize(context);
    final maxW = MediaQuery.sizeOf(context).width;
    final maxH = MediaQuery.sizeOf(context).height;

    final image = display != null
        ? Image(
            image: _imageProvider(context),
            gaplessPlayback: true,
            fit: BoxFit.contain,
            width: display.width,
            height: display.height,
          )
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: Image(
              image: _imageProvider(context),
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
          );

    final dismissProgress = (_dismissOffset / _dismissDistance).clamp(0.0, 1.0);
    final scrimProgress = (_dismissOffset / maxH).clamp(0.0, 1.0);
    final shareIcon = Theme.of(context).platform == TargetPlatform.iOS
        ? Icons.ios_share
        : Icons.share;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 1 - scrimProgress),
      extendBody: true,
      body: Stack(
        children: [
          Container(
            constraints: BoxConstraints.expand(
              height: MediaQuery.sizeOf(context).height,
            ),
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: _onDoubleTapDown,
                onDoubleTap: _toggleZoom,
                child: Transform.translate(
                  offset: Offset(0, _dismissOffset),
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    maxScale: _maxScale,
                    minScale: _minScale,
                    panEnabled: _isZoomed,
                    onInteractionStart: _onInteractionStart,
                    onInteractionEnd: _onInteractionEnd,
                    child: Center(child: image),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 1 - dismissProgress,
              child: SafeArea(
                child: Row(
                  children: [
                    _PhotoViewerButton(
                      icon: shareIcon,
                      onPressed: _sharing
                          ? null
                          : (buttonContext) => _shareImage(
                                imageUrl,
                                sharePositionOrigin: _shareOrigin(
                                  buttonContext,
                                ),
                              ),
                    ),
                    if (_sharing)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: ProgressSpinner(),
                        ),
                      ),
                    const Spacer(),
                    _PhotoViewerButton(
                      icon: Icons.close,
                      onPressed: (_) => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewRoute extends PageRouteBuilder<void> {
  _PhotoViewRoute({required WidgetBuilder builder})
      : super(
          opaque: false,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        );
}

class _PhotoViewerButton extends StatelessWidget {
  final IconData icon;
  final ValueChanged<BuildContext>? onPressed;

  const _PhotoViewerButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: const Color(0x99000000),
        shape: const CircleBorder(side: BorderSide(color: Color(0x40FFFFFF))),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onPressed == null ? null : () => onPressed!(context),
          icon: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
