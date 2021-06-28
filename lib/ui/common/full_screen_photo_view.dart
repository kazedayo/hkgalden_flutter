import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/full_screen_photo_view_cubit.dart';
import 'package:hkgalden_flutter/models/ui_state_models/full_screen_photo_view_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:image_downloader/image_downloader.dart';

class FullScreenPhotoView extends StatelessWidget {
  final String? url;
  final String? heroTag;

  const FullScreenPhotoView({Key? key, this.heroTag, this.url})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
        elevation: 20,
        color: Colors.transparent,
        child: BlocProvider(
          create: (context) => FullScreenPhotoViewCubit(),
          child:
              BlocBuilder<FullScreenPhotoViewCubit, FullScreenPhotoViewState>(
            builder: (context, state) => Row(
              children: [
                const Spacer(),
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
      body: Container(
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
      ));

  Future<void> _saveImage(BuildContext context, String url) async {
    BlocProvider.of<FullScreenPhotoViewCubit>(context)
        .setIsDownloadingImage(true);
    ImageDownloader.downloadImage(url).then((id) {
      BlocProvider.of<FullScreenPhotoViewCubit>(context)
          .setIsDownloadingImage(false);
      if (id == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('圖片下載失敗!')));
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('圖片下載成功!')));
    });
  }
}
