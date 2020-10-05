import 'dart:convert';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/context_menu_button.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/viewmodels/tag_selector_view_model.dart';
import 'package:zefyr/zefyr.dart';

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
  FocusNode _titleFocusNode;
  FocusNode _currentFocusNode;
  bool _isSending;
  final ContextMenuButtonController _menuButtonController =
      ContextMenuButtonController();

  @override
  void initState() {
    //default to tag '吹水'
    _tag = Tag(id: '02NP3MVYm', name: '吹水', color: Color(0xff457cb0));
    _channelId = '';
    _title = '';
    _controller = ZefyrController(NotusDocument());
    _titleFieldController = TextEditingController();
    _focusNode = FocusNode();
    _titleFocusNode = FocusNode();
    _isSending = false;
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _titleFocusNode.dispose();
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
        centerTitle:
            Theme.of(context).platform == TargetPlatform.iOS ? true : false,
        leading: IconButton(
            icon: Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop()),
        title: Text(
          arguments.composeMode == ComposeMode.newPost
              ? '發表主題'
              : arguments.composeMode == ComposeMode.reply
                  ? '回覆主題'
                  : '引用回覆 (#${arguments.parentReply.floor})',
          style: Theme.of(context)
              .textTheme
              .subtitle1
              .copyWith(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          ActionBarSpinner(isVisible: _isSending),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.send_rounded),
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
                                  builder: (context) {
                                    setState(() {
                                      _isSending = false;
                                    });
                                    return CustomAlertDialog(
                                        title: '注意!', content: '內文/標題不能為空');
                                  },
                                )
                              : _createThread(context, arguments)
                          : _sendReply(context, arguments);
                      // await DeltaJsonParser()
                      //     .toGaldenHtml(json.decode(_getZefyrEditorContent()));
                    },
            ),
          ),
        ],
      ),
      body: ZefyrTheme(
        data: ZefyrThemeData(
          paragraph: TextBlockTheme(
            spacing: VerticalSpacing.zero(),
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontSize: FontSize.large.size, height: 1.25),
          ),
          link: TextStyle(
              decoration: TextDecoration.none, color: Colors.blueAccent),
          heading1: TextBlockTheme(
            spacing: VerticalSpacing.zero(),
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.normal, fontSize: 33, height: 1.25),
          ),
          heading2: TextBlockTheme(
            spacing: VerticalSpacing.zero(),
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: FontSize.xxLarge.size,
                height: 1.25),
          ),
          heading3: TextBlockTheme(
            spacing: VerticalSpacing.zero(),
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: FontSize.xLarge.size,
                height: 1.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            arguments.composeMode == ComposeMode.newPost
                ? Container(
                    height: 34,
                    margin: EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ContextMenuButton(
                          width: 240,
                          height: 210,
                          xOffset: 0,
                          yOffset: 8,
                          controller: _menuButtonController,
                          closedChild: InputChip(
                              label: Text('#${_tag.name}',
                                  strutStyle: StrutStyle(height: 1.25),
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                              backgroundColor: _tag.color,
                              onPressed: () {
                                _currentFocusNode =
                                    FocusScope.of(context).focusedChild;
                                FocusScope.of(context).unfocus();
                                _menuButtonController.toggleMenu();
                              }),
                          child: _TagSelectDialog(
                            onTagSelect: (tag, channelId) {
                              FocusScope.of(context)
                                  .requestFocus(_currentFocusNode);
                              _menuButtonController.toggleMenu();
                              setState(() {
                                _tag = tag;
                                _channelId = channelId;
                              });
                            },
                          ),
                          onBarrierDismiss: () => FocusScope.of(context)
                              .requestFocus(_currentFocusNode),
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: TextField(
                            style: TextStyle(fontSize: 14),
                            strutStyle: StrutStyle(height: 1.25),
                            controller: _titleFieldController,
                            focusNode: _titleFocusNode,
                            decoration: InputDecoration(
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                labelText: '標題',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 6.8),
                                isDense: true),
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
                    constraints:
                        BoxConstraints(maxHeight: displayHeight(context) / 4),
                    child: SingleChildScrollView(
                      reverse: true,
                      scrollDirection: Axis.vertical,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: StyledHtmlView(
                        htmlString: HKGaldenHtmlParser().replyWithQuotes(
                            arguments.parentReply,
                            StoreProvider.of<AppState>(context)),
                        floor: arguments.parentReply.floor,
                      ),
                    ),
                  )
                : SizedBox(),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4),
              scrollDirection: Axis.horizontal,
              child: ZefyrToolbar.basic(controller: _controller),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ZefyrEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  expands: true,
                  autofocus: true,
                  keyboardAppearance: Brightness.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          Scaffold.of(context).showSnackBar(SnackBar(content: Text('主題發表失敗!')));
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
        builder: (context, viewModel) => SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: viewModel.channels
                .map((channel) => Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(channel.channelName,
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(color: Colors.black45)),
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
        ),
      );
}
