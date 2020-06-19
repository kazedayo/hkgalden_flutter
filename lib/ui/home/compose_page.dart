import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';
import 'package:quill_delta/quill_delta.dart';

class ComposePage extends StatefulWidget {
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
      title: Text('開post'),
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
    body: ZefyrScaffold(
      child: ZefyrEditor(controller: _controller, focusNode: _focusNode),
    ),
  );

  NotusDocument _loadDocument() {
    final Delta delta = Delta()..insert('\n');
    return NotusDocument.fromDelta(delta);
  }
}