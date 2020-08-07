import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/utils/zefyr_delegates.dart';
import 'package:hkgalden_flutter/viewmodels/tag_selector_view_model.dart';
import 'package:zefyr/zefyr.dart';
import 'package:quill_delta/quill_delta.dart';

class ComposePage extends StatefulWidget {
  @override
  _ComposePageState createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage> {
  Tag _tag;
  String _channelId;
  String _title;
  ZefyrController _controller;
  TextEditingController _titleFieldController;
  FocusNode _focusNode;
  bool _isSending;

  @override
  void initState() {
    //default to tag '吹水'
    _tag = Tag(id: '02NP3MVYm', name: '吹水', color: Color(0xff457cb0));
    _channelId = '';
    _title = '';
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
  Widget build(BuildContext context) {
    final ComposePageArguments arguments =
        ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop()),
        title: Text(arguments.composeMode == ComposeMode.newPost
            ? '發表主題'
            : arguments.composeMode == ComposeMode.reply
                ? '回覆主題'
                : '引用回覆 (#${arguments.parentReply.floor})'),
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
                      arguments.composeMode == ComposeMode.newPost
                          ? _title == '' ||
                                  _controller.document.toString() == '/n'
                              ? showModal(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('注意!'),
                                    content: Text('內文/標題不能為空'),
                                    actions: <Widget>[
                                      FlatButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              _isSending = false;
                                            });
                                          },
                                          child: Text('OK'))
                                    ],
                                  ),
                                )
                              : _createThread(context, arguments)
                          : _sendReply(context, arguments);
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
              arguments.composeMode == ComposeMode.newPost
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
                                      onTagSelect: (tag, channelId) {
                                        setState(() {
                                          _tag = tag;
                                          _channelId = channelId;
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
              arguments.composeMode == ComposeMode.quotedReply
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3),
                      child: SingleChildScrollView(
                        reverse: true,
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: StyledHtmlView(
                          htmlString: HKGaldenHtmlParser()
                              .replyWithQuotes(arguments.parentReply),
                          floor: arguments.parentReply.floor,
                        ),
                      ),
                    )
                  : SizedBox(),
              Expanded(
                child: ZefyrEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  selectionControls: materialTextSelectionControls,
                  toolbarDelegate: CustomZefyrToolbarDelegate(),
                  imageDelegate: CustomZefyrImageDelegate(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  NotusDocument _loadDocument() {
    final Delta delta = Delta()..insert('\n');
    return NotusDocument.fromDelta(delta);
  }

  String _getZefyrEditorContent() {
    final content = _controller.document.toDelta();
    return json.encode(content);
  }

  Future<void> _createThread(
      BuildContext context, ComposePageArguments arguments) async {
    HKGaldenApi()
        .createThread(
            _title,
            [_tag.id],
            await DeltaJsonParser()
                .toGaldenHtml(json.decode(_getZefyrEditorContent())))
        .then((threadId) {
      setState(() {
        _isSending = false;
        if (threadId != null) {
          Navigator.pop(context);
          arguments.onCreateThread(_channelId);
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('回覆發送失敗!')));
        }
      });
    });
  }

  Future<void> _sendReply(
      BuildContext context, ComposePageArguments arguments) async {
    HKGaldenApi()
        .sendReply(
      arguments.threadId,
      await DeltaJsonParser()
          .toGaldenHtml(json.decode(_getZefyrEditorContent())),
      parentId: arguments.composeMode == ComposeMode.quotedReply
          ? arguments.parentReply.replyId
          : '',
    )
        .then((sentReply) {
      setState(() {
        _isSending = false;
        if (sentReply != null) {
          Navigator.pop(context);
          arguments.onSent(sentReply);
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('回覆發送失敗!')));
        }
      });
    });
  }
}

class _TagSelectDialog extends StatelessWidget {
  final Function(Tag, String) onTagSelect;

  _TagSelectDialog({this.onTagSelect});

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, TagSelectorViewModel>(
        distinct: true,
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
                                      onTagSelect(tag, channel.channelId);
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
