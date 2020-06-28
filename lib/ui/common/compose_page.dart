import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:zefyr/zefyr.dart';
import 'package:quill_delta/quill_delta.dart';

class ComposePage extends StatefulWidget {
  final ComposeMode composeMode;

  const ComposePage({Key key, this.composeMode}) : super(key: key);

  @override
  _ComposePageState createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  ZefyrController _controller;
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    final document = _loadDocument();
    _controller = ZefyrController(document);
    _focusNode = FocusNode();
  }

  @override 
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: widget.composeMode == ComposeMode.newPost ? 
        Text('開post') 
        : Text('回覆主題'),
      //automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () => DeltaJsonParser().toGaldenHtml(json.decode(_getZefyrEditorContent())),
        ),
      ],
    ),
    body: ZefyrTheme(
      data: ZefyrThemeData(
        toolbarTheme: ToolbarTheme.fallback(context).copyWith(
          color: Theme.of(context).primaryColor,
        )
      ),
      child: ZefyrScaffold(
        child: ZefyrEditor(
          controller: _controller, 
          focusNode: _focusNode,
        ),
      ),
    )
  );

  NotusDocument _loadDocument() {
    final Delta delta = Delta()..insert('\n');
    return NotusDocument.fromDelta(delta);
  }

  String _getZefyrEditorContent() {
    final content = _controller.document.toDelta();
    return json.encode(content);
  }
}

