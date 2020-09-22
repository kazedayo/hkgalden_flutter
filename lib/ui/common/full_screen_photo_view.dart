import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:image_downloader/image_downloader.dart';

class FullScreenPhotoView extends StatefulWidget {
  final String url;
  final String heroTag;

  const FullScreenPhotoView({Key key, this.heroTag, this.url})
      : super(key: key);

  @override
  _FullScreenPhotoViewState createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  //drag to dismiss code: https://github.com/Furkankyl/full_screen_image/blob/master/lib/full_screen_image.dart
  bool _isDownloadingImage;

  @override
  void initState() {
    _isDownloadingImage = false;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    precacheImage(CachedNetworkImageProvider(widget.url), context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        bottomNavigationBar: BottomAppBar(
          elevation: 20,
          color: Colors.transparent,
          child: Row(
            children: [
              Spacer(),
              ActionBarSpinner(isVisible: _isDownloadingImage),
              Builder(
                builder: (context) => GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: String.fromCharCode(0x0e171),
                              style: TextStyle(
                                  fontSize: 25,
                                  shadows: [Shadow(blurRadius: 5)],
                                  fontFamily: 'MaterialIcons'))
                        ]),
                      ),
                    ),
                    onTap: _isDownloadingImage
                        ? null
                        : () => _saveImage(context, widget.url)),
              ),
            ],
          ),
        ),
        body: Container(
          constraints: BoxConstraints.expand(
            height: displayHeight(context),
          ),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 1.0,
              child: Hero(
                  tag: widget.heroTag,
                  child: CachedNetworkImage(
                      fadeInDuration: Duration.zero,
                      placeholder: (context, url) => CachedNetworkImage(
                            imageUrl: widget.url,
                            memCacheWidth: displayWidth(context).toInt(),
                          ),
                      imageUrl: widget.url)),
            ),
          ),
        ),
      );

  _saveImage(BuildContext context, String url) async {
    setState(() {
      _isDownloadingImage = true;
    });
    ImageDownloader.downloadImage(url).then((id) {
      setState(() {
        _isDownloadingImage = false;
      });
      if (id == null) {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('圖片下載失敗!')));
        return;
      }
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('圖片下載成功!')));
    });
  }
}
