import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenPhotoView extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenPhotoView({Key key, this.imageUrl, this.heroTag}) : super(key: key);

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

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: <Widget>[
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.save_alt), 
            onPressed: _isDownloadingImage ? null : () => _downloadImage(context, widget.imageUrl)
          ),
        ),
        IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
      ],
    ),
    body: Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height,
      ),
      child: PhotoView.customChild(
        backgroundDecoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Hero(
          tag: widget.heroTag,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            filterQuality: FilterQuality.high,
          ),
        ),
        //heroAttributes: PhotoViewHeroAttributes(tag: heroTag, transitionOnUserGestures: true),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
      ),
    ),
  );

  _downloadImage(BuildContext context, String url) async {
    try {
      setState(() {
        _isDownloadingImage = true;
      });
      // Saved with this method.
      await ImageDownloader.downloadImage(url, destination: AndroidDestinationType.directoryPictures).then((value) {
        setState(() {
            _isDownloadingImage = false;
          });
        if (value == null) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text('圖片下載失敗!'))
          );
          return;
        }
        Scaffold.of(context).showSnackBar(
          SnackBar(content: Text('圖片下載成功!'))
        );
      });
    } on PlatformException catch (error) {
      print(error);
    }
  }
}