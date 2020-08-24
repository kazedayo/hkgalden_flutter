import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:image_downloader/image_downloader.dart';

class FullScreenPhotoView extends StatefulWidget {
  final AdvancedNetworkImage image;
  final String heroTag;

  const FullScreenPhotoView({Key key, this.image, this.heroTag})
      : super(key: key);

  @override
  _FullScreenPhotoViewState createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<FullScreenPhotoView> {
  //drag to dismiss code: https://github.com/Furkankyl/full_screen_image/blob/master/lib/full_screen_image.dart
  bool _isDownloadingImage;
  String _heroTag;
  @override
  void initState() {
    _isDownloadingImage = false;
    _heroTag = widget.heroTag;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        bottomNavigationBar: BottomAppBar(
          color: Colors.transparent,
          elevation: 30,
          child: Row(
            children: [
              IconButton(
                  splashRadius: 25.0,
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop()),
              Spacer(),
              ActionBarSpinner(isVisible: _isDownloadingImage),
              Builder(
                builder: (context) => IconButton(
                    splashRadius: 25.0,
                    icon: Icon(Icons.save_alt),
                    onPressed: _isDownloadingImage
                        ? null
                        : () => _saveImage(context, widget.image.url)),
              ),
            ],
          ),
        ),
        body: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Hero(
            tag: _heroTag,
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 1.0,
              child: Image(image: widget.image),
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
