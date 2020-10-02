//hacky way to hide button on toolbar before zefyr 1.0 release

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/networking/image_upload_api.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:zefyr/zefyr.dart';

class CustomZefyrToolbarDelegate implements ZefyrToolbarDelegate {
  static const kDefaultButtonIcons = {
    ZefyrToolbarAction.bold: Icons.format_bold,
    ZefyrToolbarAction.italic: Icons.format_italic,
    ZefyrToolbarAction.link: Icons.link,
    ZefyrToolbarAction.unlink: Icons.link_off,
    ZefyrToolbarAction.clipboardCopy: Icons.content_copy,
    ZefyrToolbarAction.openInBrowser: Icons.open_in_new,
    ZefyrToolbarAction.heading: Icons.format_size,
    ZefyrToolbarAction.bulletList: Icons.format_list_bulleted,
    ZefyrToolbarAction.numberList: Icons.format_list_numbered,
    ZefyrToolbarAction.code: Icons.code,
    ZefyrToolbarAction.quote: Icons.format_quote,
    ZefyrToolbarAction.horizontalRule: Icons.remove,
    ZefyrToolbarAction.image: Icons.photo,
    ZefyrToolbarAction.cameraImage: Icons.photo_camera,
    ZefyrToolbarAction.galleryImage: Icons.photo_library,
    ZefyrToolbarAction.hideKeyboard: Icons.keyboard_hide,
    ZefyrToolbarAction.close: Icons.close,
    ZefyrToolbarAction.confirm: Icons.check,
  };

  static const kSpecialIconSizes = {
    ZefyrToolbarAction.unlink: 20.0,
    ZefyrToolbarAction.clipboardCopy: 20.0,
    ZefyrToolbarAction.openInBrowser: 20.0,
    ZefyrToolbarAction.close: 20.0,
    ZefyrToolbarAction.confirm: 20.0,
  };

  static const kDefaultButtonTexts = {
    ZefyrToolbarAction.headingLevel1: 'H1',
    ZefyrToolbarAction.headingLevel2: 'H2',
    ZefyrToolbarAction.headingLevel3: 'H3',
  };

  @override
  Widget buildButton(BuildContext context, ZefyrToolbarAction action,
      {VoidCallback onPressed}) {
    //final theme = Theme.of(context);
    final List<ZefyrToolbarAction> enabledActions = [
      ZefyrToolbarAction.image,
      ZefyrToolbarAction.cameraImage,
      ZefyrToolbarAction.galleryImage,
      ZefyrToolbarAction.link,
      ZefyrToolbarAction.bold,
      ZefyrToolbarAction.italic,
      ZefyrToolbarAction.heading,
      ZefyrToolbarAction.hideKeyboard,
      ZefyrToolbarAction.confirm,
      ZefyrToolbarAction.clipboardCopy,
      ZefyrToolbarAction.close,
      ZefyrToolbarAction.unlink
    ];
    if (enabledActions.contains(action)) {
      final icon = kDefaultButtonIcons[action];
      final size = kSpecialIconSizes[action];
      return ZefyrButton.icon(
        action: action,
        icon: icon,
        iconSize: size,
        onPressed: onPressed,
      );
    } else if (action == ZefyrToolbarAction.headingLevel1 ||
        action == ZefyrToolbarAction.headingLevel2 ||
        action == ZefyrToolbarAction.headingLevel3) {
      final text = kDefaultButtonTexts[action];
      final style = Theme.of(context)
          .textTheme
          .caption
          .copyWith(fontWeight: FontWeight.bold, fontSize: 14.0);
      return ZefyrButton.text(
        action: action,
        text: text,
        style: style,
        onPressed: onPressed,
      );
    } else {
      return SizedBox();
    }
  }
}

//insert image locally first
class CustomZefyrImageDelegate implements ZefyrImageDelegate {
  @override
  Future<String> pickImage(source) async {
    final picker = ImagePicker();
    final file = await picker.getImage(source: source);
    if (file == null) return null;
    return await ImageUploadApi().uploadImage(file.path);
  }

  @override
  Widget buildImage(BuildContext context, String url) {
    return CachedNetworkImage(
      imageUrl: url,
      placeholder: (context, url) => ProgressSpinner(),
    );
  }

  @override
  ImageSource get cameraSource => ImageSource.camera;

  @override
  ImageSource get gallerySource => ImageSource.gallery;
}
