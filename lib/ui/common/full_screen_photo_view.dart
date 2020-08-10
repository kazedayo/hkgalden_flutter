import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';

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
                  splashRadius: 25.0,
                  icon: Icon(Icons.save_alt),
                  onPressed: _isDownloadingImage
                      ? null
                      : () => _saveImage(context, widget.imageUrl)),
            ),
            IconButton(
                splashRadius: 25.0,
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop())
          ],
        ),
        body: Container(
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: InteractiveViewer(
            minScale: 1.0,
            maxScale: 3.0,
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
          ),
        ),
      );

  _saveImage(BuildContext context, String url) async {
    setState(() {
      _isDownloadingImage = true;
    });
    GallerySaver.saveImage(url).then((success) {
      setState(() {
        _isDownloadingImage = false;
      });
      if (success == false) {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text('圖片下載失敗!')));
        return;
      }
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('圖片下載成功!')));
    });
  }
}
