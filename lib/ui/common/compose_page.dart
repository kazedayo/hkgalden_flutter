import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:zefyr/zefyr.dart';
import 'package:quill_delta/quill_delta.dart';

class ComposePage extends StatefulWidget {
  final ComposeMode composeMode;
  final int threadId;

  const ComposePage({Key key, this.composeMode, this.threadId})
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: widget.composeMode == ComposeMode.newPost
            ? Text('開post')
            : Text('回覆主題'),
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
          child: ZefyrEditor(
            controller: _controller,
            focusNode: _focusNode,
          ),
        ),
      ));

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
            DeltaJsonParser()
                .toGaldenHtml(json.decode(_getZefyrEditorContent())))
        .then((sentReply) {
      setState(() {
        _isSendingReply = false;
        if (sentReply != null) {
          Navigator.pop(context);
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('回覆發送失敗!')));
        }
      });
    });
  }
}
