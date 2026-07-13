import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/full_screen_photo_view_cubit.dart';
import 'package:hkgalden_flutter/models/ui_state_models/full_screen_photo_view_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';

class FullScreenPhotoView extends StatelessWidget {
  final String? url;
  final String? heroTag;

  const FullScreenPhotoView({super.key, this.heroTag, this.url});

  /// Same decode width as [StyledHtmlView] so the viewer reuses the thread
  /// image cache entry instead of decoding a multi‑megapixel full-res bitmap
  /// that thrashing the thread page's [ImageCache] cap.
  static int _screenCacheWidth(BuildContext context) {
    return (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .toInt();
  }

  /// Keep the image element mounted during flight (matches thread [Hero]s).
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
    final cacheWidth = _screenCacheWidth(context);
    final imageUrl = url!;
    final tag = heroTag;

    final image = Image(
      image: ResizeImage(
        NetworkImage(imageUrl),
        width: cacheWidth,
      ),
      gaplessPlayback: true,
      fit: BoxFit.contain,
      width: displayWidth(context),
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
