import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/zoomable.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:image_downloader/image_downloader.dart';

class FullScreenPhotoView extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenPhotoView({Key key, this.imageUrl, this.heroTag})
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
  Widget build(BuildContext context) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
              splashRadius: 25.0,
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop()),
          backgroundColor: Colors.transparent,
          elevation: 30,
          actions: <Widget>[
            ActionBarSpinner(isVisible: _isDownloadingImage),
            Builder(
              builder: (context) => IconButton(
                  splashRadius: 25.0,
                  icon: Icon(Icons.save_alt),
                  onPressed: _isDownloadingImage
                      ? null
                      : () => _saveImage(context, widget.imageUrl)),
            ),
          ],
        ),
        body: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: Hero(
            tag: widget.heroTag,
            child: ZoomableWidget(
              autoCenter: true,
              maxScale: 2.5,
              minScale: 1.0,
              zoomSteps: 2,
              child: Image(image: AdvancedNetworkImage(widget.imageUrl)),
              onTap: () => Navigator.of(context).pop(),
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
