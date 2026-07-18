import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/full_screen_photo_view_cubit.dart';
import 'package:hkgalden_flutter/models/ui_state_models/full_screen_photo_view_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';

class FullScreenPhotoView extends StatefulWidget {
  final String? url;
  final String? heroTag;

  final int? intrinsicWidth;
  final int? intrinsicHeight;

  const FullScreenPhotoView({
    super.key,
    this.heroTag,
    this.url,
    this.intrinsicWidth,
    this.intrinsicHeight,
  });

  @override
  State<FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  Size? _naturalSize;

  ImageStream? _sizeStream;
  ImageStreamListener? _sizeListener;

  @override
  void initState() {
    super.initState();
    _naturalSize = _sizeFromAttrsOrCache();
    if (_naturalSize == null) {
      _listenForNaturalSize();
    }
  }

  @override
  void dispose() {
    _stopSizeListener();
    super.dispose();
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
      final r = ratio ??
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
          ImageAspectRatioStore.instance.save(
            url,
            ratio,
            naturalWidth: w,
          );
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

    final maxW = displayWidth(context);
    final maxH = displayHeight(context);
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
    final screenCap =
        math.max(1, (displayWidth(context) * dpr).round());
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
    return ResizeImage(
      network,
      width: _decodeWidth(context),
    );
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
    final imageUrl = widget.url!;
    final tag = widget.heroTag;
    final display = _displaySize(context);
    final maxW = displayWidth(context);
    final maxH = displayHeight(context);

    final image = display != null
        ? Image(
            image: _imageProvider(context),
            gaplessPlayback: true,
            fit: BoxFit.contain,
            width: display.width,
            height: display.height,
          )
        : ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              maxHeight: maxH,
            ),
            child: Image(
              image: _imageProvider(context),
              gaplessPlayback: true,
              fit: BoxFit.contain,
            ),
          );

    return BlocProvider(
      create: (context) => FullScreenPhotoViewCubit(),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: Stack(
          children: [
            Container(
              constraints: BoxConstraints.expand(
                height: displayHeight(context),
              ),
              child: Dismissible(
                key: ValueKey(imageUrl),
                direction: DismissDirection.vertical,
                resizeDuration: null,
                onDismissed: (direction) {
                  Navigator.of(context).pop();
                },
                child: InteractiveViewer(
                  maxScale: 3.0,
                  minScale: 1.0,
                  child: Center(
                    child: tag == null
                        ? image
                        : Hero(
                            tag: tag,
                            placeholderBuilder: _heroPlaceholder,
                            child: Material(
                              type: MaterialType.transparency,
                              child: image,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: BlocConsumer<FullScreenPhotoViewCubit,
                    FullScreenPhotoViewState>(
                  listenWhen: (previous, current) =>
                      previous.downloadSuccess != current.downloadSuccess &&
                      current.downloadSuccess != null,
                  listener: (context, state) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(state.downloadSuccess == true
                            ? '圖片下載成功!'
                            : '圖片下載失敗!')));
                  },
                  builder: (context, state) => Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ActionBarSpinner(isVisible: state.isDownloadingImage),
                      Builder(
                        builder: (context) => TextButton(
                          clipBehavior: Clip.hardEdge,
                          onPressed: state.isDownloadingImage
                              ? null
                              : () => context
                                  .read<FullScreenPhotoViewCubit>()
                                  .saveImage(imageUrl),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                    text: String.fromCharCode(0xF0125),
                                    style: const TextStyle(
                                        fontSize: 25,
                                        shadows: [Shadow(blurRadius: 5)],
                                        fontFamily: 'MaterialIcons'))
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
