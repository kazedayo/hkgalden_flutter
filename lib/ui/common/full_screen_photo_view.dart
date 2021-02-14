import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:paulonia_cache_image/paulonia_cache_image.dart';

class FullScreenPhotoView extends StatefulWidget {
  final String url;
  final String heroTag;

  const FullScreenPhotoView({Key key, this.heroTag, this.url})
      : super(key: key);

  @override
  _FullScreenPhotoViewState createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  bool _isDownloadingImage;

  @override
  void initState() {
    _isDownloadingImage = false;
    super.initState();
  }

  // @override
  // void didChangeDependencies() {
  //   precacheImage(CachedNetworkImageProvider(widget.url), context);
  //   super.didChangeDependencies();
  // }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        bottomNavigationBar: BottomAppBar(
          elevation: 20,
          color: Colors.transparent,
          child: Row(
            children: [
              const Spacer(),
              ActionBarSpinner(isVisible: _isDownloadingImage),
              Builder(
                builder: (context) => FlatButton(
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  onPressed: _isDownloadingImage
                      ? null
                      : () => _saveImage(context, widget.url),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                            text: String.fromCharCode(0xe9a2),
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
                  tag: widget.heroTag,
                  child: Image(image: PCacheImage(widget.url))),
            ),
          ),
        ),
      );

  Future<void> _saveImage(BuildContext context, String url) async {
    setState(() {
      _isDownloadingImage = true;
    });
    ImageDownloader.downloadImage(url).then((id) {
      setState(() {
        _isDownloadingImage = false;
      });
      if (id == null) {
        Scaffold.of(context)
            .showSnackBar(const SnackBar(content: Text('圖片下載失敗!')));
        return;
      }
      Scaffold.of(context)
          .showSnackBar(const SnackBar(content: Text('圖片下載成功!')));
    });
  }
}
