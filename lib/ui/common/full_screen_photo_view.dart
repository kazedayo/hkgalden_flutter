import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:photo_view/photo_view.dart';

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
  double _initialPositionY = 0;
  double _currentPositionY = 0;
  double _positionYDelta = 0;
  double _disposeLimit = 150;
  Duration _animationDuration = Duration.zero;

  @override
  void initState() {
    _isDownloadingImage = false;
    super.initState();
  }

  void _startVerticalDrag(details) {
    setState(() {
      _initialPositionY = details.globalPosition.dy;
    });
  }

  void _whileVerticalDrag(details) {
    setState(() {
      _currentPositionY = details.globalPosition.dy;
      _positionYDelta = _currentPositionY - _initialPositionY;
    });
  }

  _endVerticalDrag(DragEndDetails details) {
    if (_positionYDelta > _disposeLimit || _positionYDelta < -_disposeLimit) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _animationDuration = Duration(milliseconds: 300);
        _positionYDelta = 0;
      });

      Future.delayed(_animationDuration).then((_) {
        setState(() {
          _animationDuration = Duration.zero;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: <Widget>[
            ActionBarSpinner(isVisible: _isDownloadingImage),
            Builder(
              builder: (context) => IconButton(
                  icon: Icon(Icons.save_alt),
                  onPressed: _isDownloadingImage
                      ? null
                      : () => _downloadImage(context, widget.imageUrl)),
            ),
            IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop())
          ],
        ),
        body: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: PhotoView.customChild(
            gestureDetectorBehavior: HitTestBehavior.opaque,
            backgroundDecoration:
                BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
            child: GestureDetector(
              onVerticalDragStart: (details) => _startVerticalDrag(details),
              onVerticalDragUpdate: (details) => _whileVerticalDrag(details),
              onVerticalDragEnd: (details) => _endVerticalDrag(details),
              child: Stack(
                children: <Widget>[
                  AnimatedPositioned(
                    duration: _animationDuration,
                    curve: Curves.fastOutSlowIn,
                    top: 0 + _positionYDelta,
                    bottom: 0 - _positionYDelta,
                    left: 0,
                    right: 0,
                    child: Hero(
                      tag: widget.heroTag,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrl,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ],
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
      await ImageDownloader.downloadImage(url,
              destination: AndroidDestinationType.directoryPictures)
          .then((value) {
        setState(() {
          _isDownloadingImage = false;
        });
        if (value == null) {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('圖片下載失敗!')));
          return;
        }
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('圖片下載成功!')));
      });
    } on PlatformException catch (error) {
      print(error);
    }
  }
}
