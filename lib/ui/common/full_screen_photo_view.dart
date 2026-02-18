import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:hkgalden_flutter/bloc/cubit/full_screen_photo_view_cubit.dart';
import 'package:hkgalden_flutter/models/ui_state_models/full_screen_photo_view_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:path_provider/path_provider.dart';

class FullScreenPhotoView extends StatelessWidget {
  final String? url;
  final String? heroTag;

  const FullScreenPhotoView({super.key, this.heroTag, this.url});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => FullScreenPhotoViewCubit(),
        child: Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                Container(
                  constraints: BoxConstraints.expand(
                    height: displayHeight(context),
                  ),
                  child: Dismissible(
                    key: UniqueKey(),
                    direction: DismissDirection.vertical,
                    resizeDuration: null,
                    onDismissed: (direction) {
                      Navigator.of(context).pop();
                    },
                    child: InteractiveViewer(
                      maxScale: 3.0,
                      minScale: 1.0,
                      child: Hero(
                        tag: heroTag!,
                        child: Image.network(url!),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: BlocBuilder<FullScreenPhotoViewCubit,
                        FullScreenPhotoViewState>(
                      builder: (context, state) => Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ActionBarSpinner(isVisible: state.isDownloadingImage),
                          Builder(
                            builder: (context) => TextButton(
                              clipBehavior: Clip.hardEdge,
                              onPressed: state.isDownloadingImage
                                  ? null
                                  : () => _saveImage(context, url!),
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
            )),
      );

  Future<void> _saveImage(BuildContext context, String url) async {
    BlocProvider.of<FullScreenPhotoViewCubit>(context)
        .setIsDownloadingImage(true);
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = '${tempDir.path}/$fileName';
      await Dio().download(url, filePath);
      await Gal.putImage(filePath);
      // Clean up temp file
      try {
        await File(filePath).delete();
      } catch (_) {}
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('圖片下載成功!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('圖片下載失敗!')));
      }
    } finally {
      if (context.mounted) {
        BlocProvider.of<FullScreenPhotoViewCubit>(context)
            .setIsDownloadingImage(false);
      }
    }
  }
}
