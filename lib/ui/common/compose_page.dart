import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/utils/zefyr_delegates.dart';
import 'package:hkgalden_flutter/viewmodels/tag_selector_view_model.dart';
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
  Tag _tag;
  String _title;
  ZefyrController _controller;
  TextEditingController _titleFieldController;
  FocusNode _focusNode;
  bool _isSending;

  @override
  void initState() {
    //default to tag '吹水'
    _tag = Tag(id: '02NP3MVYm', name: '吹水', color: Color(0xff457cb0));
    final document = _loadDocument();
    _controller = ZefyrController(document);
    _titleFieldController = TextEditingController();
    _focusNode = FocusNode();
    _isSending = false;
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _titleFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop()),
          title: Text(widget.composeMode == ComposeMode.newPost
              ? '發表主題'
              : widget.composeMode == ComposeMode.reply
                  ? '回覆主題'
                  : '引用回覆 (#${widget.parentReply.floor})'),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            ActionBarSpinner(isVisible: _isSending),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSending
                    ? null
                    : () async {
                        setState(() {
                          _isSending = true;
                        });
                        widget.composeMode == ComposeMode.newPost
                            ? _sendThread(context)
                            : _sendReply(context);
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
                widget.composeMode == ComposeMode.newPost
                    ? Container(
                        margin: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            InputChip(
                              label: Text('#${_tag.name}',
                                  strutStyle: StrutStyle(height: 1.25),
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                              backgroundColor: _tag.color,
                              onPressed: () => showModal<void>(
                                  context: context,
                                  builder: (context) => _TagSelectDialog(
                                        onTagSelect: (tag) {
                                          setState(() {
                                            _tag = tag;
                                          });
                                        },
                                      )),
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _titleFieldController,
                                decoration: InputDecoration(
                                  labelText: '標題',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _title = value;
                                  });
                                },
                              ),
                            )
                          ],
                        ))
                    : SizedBox(),
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

  Future<void> _sendThread(BuildContext context) async {}

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
        _isSending = false;
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

class _TagSelectDialog extends StatelessWidget {
  final Function(Tag) onTagSelect;

  _TagSelectDialog({this.onTagSelect});

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, TagSelectorViewModel>(
        converter: (store) => TagSelectorViewModel.create(store),
        builder: (context, viewModel) => SimpleDialog(
          title: Text('選擇標籤'),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: viewModel.channels
              .map((channel) => Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(channel.channelName,
                            style: Theme.of(context).textTheme.caption),
                        Wrap(
                          spacing: 8,
                          children: channel.tags
                              .map((tag) => InputChip(
                                    label: Text('#${tag.name}',
                                        strutStyle: StrutStyle(height: 1.25),
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                    backgroundColor: tag.color,
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      onTagSelect(tag);
                                    },
                                  ))
                              .toList(),
                        )
                      ],
                    ),
                  ))
              .toList(),
        ),
      );
}
