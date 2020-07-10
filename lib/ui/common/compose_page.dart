import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/utils/zefyr_delegates.dart';
import 'package:zefyr/zefyr.dart';
import 'package:quill_delta/quill_delta.dart';

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
                    : () async {
                        setState(() {
                          _isSendingReply = true;
                        });
                        _sendReply(context);
                        // await DeltaJsonParser().toGaldenHtml(
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
                    toolbarDelegate: CustomZefyrToolbarDelegate(),
                    imageDelegate: CustomZefyrImageDelegate(),
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

  Future<void> _sendReply(BuildContext context) async {
    HKGaldenApi()
        .sendReply(
      widget.threadId,
      await DeltaJsonParser()
          .toGaldenHtml(json.decode(_getZefyrEditorContent())),
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
