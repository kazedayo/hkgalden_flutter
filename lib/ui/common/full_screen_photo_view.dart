import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenPhotoView extends StatelessWidget {
  final ImageProvider imageProvider;
  final String heroTag;

  const FullScreenPhotoView({Key key, this.imageProvider, this.heroTag}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints.expand(
      height: MediaQuery.of(context).size.height,
    ),
    child: PhotoView(
      imageProvider: imageProvider,
      heroAttributes: PhotoViewHeroAttributes(tag: heroTag, transitionOnUserGestures: true),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered,
    ),
  );
}