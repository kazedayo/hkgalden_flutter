import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenPhotoView extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenPhotoView({Key key, this.imageUrl, this.heroTag}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Color(0x88000000),
      elevation: 0,
      actions: <Widget>[
        IconButton(icon: Icon(Icons.save_alt), onPressed: () => null),
        IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.of(context).pop())
      ],
    ),
    body: Container(
      constraints: BoxConstraints.expand(
        height: MediaQuery.of(context).size.height,
      ),
      child: PhotoView.customChild(
        child: Hero(
          tag: heroTag,
          child: CachedNetworkImage(imageUrl: imageUrl),
        ),
        //heroAttributes: PhotoViewHeroAttributes(tag: heroTag, transitionOnUserGestures: true),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
      ),
    ),
  );
}