import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:zefyr/zefyr.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:image_picker/image_picker.dart';

class ComposePage extends StatefulWidget {
  final ComposeMode composeMode;
  final int threadId;
  final Reply parentReply;
  final Function(Reply) onSent;

  const ComposePage(
      {Key key, this.composeMode, this.threadId, this.parentReply, this.onSent})
      : super(key: key);

  @override
  _ComposePageState createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  ZefyrController _controller;
  FocusNode _focusNode;
  bool _isSendingReply;

  @override
  void initState() {
    super.initState();
    final document = _loadDocument();
    _controller = ZefyrController(document);
    _focusNode = FocusNode();
    _isSendingReply = false;
  }

  @override
  void dispose() {
    _focusNode.unfocus();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.composeMode == ComposeMode.newPost
              ? '開post'
              : widget.composeMode == ComposeMode.reply
                  ? '回覆主題'
                  : '引用回覆 (#${widget.parentReply.floor})'),
          //automaticallyImplyLeading: false,
          actions: <Widget>[
            ActionBarSpinner(isVisible: _isSendingReply),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSendingReply
                    ? null
                    : () {
                        setState(() {
                          _isSendingReply = true;
                        });
                        _sendReply(context);
                        // DeltaJsonParser().toGaldenHtml(
                        //     json.decode(_getZefyrEditorContent()));
                      },
              ),
            ),
          ],
        ),
        body: ZefyrTheme(
          data: ZefyrThemeData(
              toolbarTheme: ToolbarTheme.fallback(context).copyWith(
            color: Theme.of(context).primaryColor,
          )),
          child: ZefyrScaffold(
            child: Column(
              children: <Widget>[
                widget.composeMode == ComposeMode.quotedReply
                    ? ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.3),
                        child: SingleChildScrollView(
                          reverse: true,
                          scrollDirection: Axis.vertical,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: StyledHtmlView(
                            htmlString: HKGaldenHtmlParser()
                                .replyWithQuotes(widget.parentReply),
                            floor: widget.parentReply.floor,
                          ),
                        ),
                      )
                    : SizedBox(),
                Expanded(
                  child: ZefyrEditor(
                    controller: _controller,
                    focusNode: _focusNode,
                    toolbarDelegate: _CustomZefyrToolbarDelegate(),
                    imageDelegate: _CustomZefyrImageDelegate(),
                  ),
                )
              ],
            ),
          ),
        ),
      );

  NotusDocument _loadDocument() {
    final Delta delta = Delta()..insert('\n');
    return NotusDocument.fromDelta(delta);
  }

  String _getZefyrEditorContent() {
    final content = _controller.document.toDelta();
    return json.encode(content);
  }

  void _sendReply(BuildContext context) {
    HKGaldenApi()
        .sendReply(
      widget.threadId,
      DeltaJsonParser().toGaldenHtml(json.decode(_getZefyrEditorContent())),
      parentId: widget.composeMode == ComposeMode.quotedReply
          ? widget.parentReply.replyId
          : '',
    )
        .then((sentReply) {
      setState(() {
        _isSendingReply = false;
        if (sentReply != null) {
          Navigator.pop(context);
          widget.onSent(sentReply);
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('回覆發送失敗!')));
        }
      });
    });
  }
}

//hacky way to hide button on toolbar before zefyr 1.0 release
class _CustomZefyrToolbarDelegate implements ZefyrToolbarDelegate {
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
    final theme = Theme.of(context);
    if (action == ZefyrToolbarAction.bold ||
        action == ZefyrToolbarAction.italic ||
        action == ZefyrToolbarAction.image ||
        action == ZefyrToolbarAction.cameraImage ||
        action == ZefyrToolbarAction.galleryImage ||
        action == ZefyrToolbarAction.hideKeyboard) {
      final icon = kDefaultButtonIcons[action];
      final size = kSpecialIconSizes[action];
      return ZefyrButton.icon(
        action: action,
        icon: icon,
        iconSize: size,
        onPressed: onPressed,
      );
    } else {
      return SizedBox();
    }
  }
}

//insert image locally first
class _CustomZefyrImageDelegate implements ZefyrImageDelegate {
  @override
  Future<String> pickImage(source) async {
    final picker = ImagePicker();
    final file = await picker.getImage(source: source);
    if (file == null) return null;
    return file.path;
  }

  @override
  Widget buildImage(BuildContext context, String key) {
    final file = File.fromUri(Uri.parse(key));
    final image = FileImage(file);
    return Image(image: image);
  }

  @override
  ImageSource get cameraSource => ImageSource.camera;

  @override
  ImageSource get gallerySource => ImageSource.gallery;
}
