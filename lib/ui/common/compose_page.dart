import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/style.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/utils/custom_icons.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/viewmodels/tag_selector_view_model.dart';
import 'package:zefyr/zefyr.dart';

class ComposePage extends StatefulWidget {
  final ComposeMode composeMode;
  final int threadId;
  final Reply parentReply;
  final Function(Reply) onSent;
  final Function(String) onCreateThread;

  const ComposePage(
      {Key key,
      @required this.composeMode,
      this.threadId,
      this.parentReply,
      this.onSent,
      this.onCreateThread})
      : super(key: key);

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

  @override
  void initState() {
    //default to tag '吹水'
    _tag = const Tag(id: '02NP3MVYm', name: '吹水', color: Color(0xff457cb0));
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
    return Scaffold(
      appBar: AppBar(
        centerTitle:
            Theme.of(context).platform == TargetPlatform.iOS ? true : false,
        title: Text(
          widget.composeMode == ComposeMode.newPost
              ? '發表主題'
              : widget.composeMode == ComposeMode.reply
                  ? '回覆主題'
                  : '引用回覆 (#${widget.parentReply.floor})',
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
                      widget.composeMode == ComposeMode.newPost
                          ? _title == '' ||
                                  _controller.document.toString() == '/n'
                              ? showCustomDialog(
                                  context: context,
                                  builder: (context) {
                                    setState(() {
                                      _isSending = false;
                                    });
                                    return const CustomAlertDialog(
                                        title: '注意!', content: '內文/標題不能為空');
                                  },
                                )
                              : _createThread(context)
                          : _sendReply(context);
                      // await DeltaJsonParser()
                      //     .toGaldenHtml(json.decode(_getZefyrEditorContent()));
                    },
            ),
          ),
        ],
      ),
      body: ZefyrTheme(
        data: ZefyrThemeData(
          strikethrough:
              const TextStyle(decoration: TextDecoration.lineThrough),
          paragraph: TextBlockTheme(
            spacing: const VerticalSpacing.zero(),
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontSize: FontSize.large.size, height: 1.25),
          ),
          link: const TextStyle(
              decoration: TextDecoration.none, color: Colors.blueAccent),
          heading1: TextBlockTheme(
            spacing: const VerticalSpacing.zero(),
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.normal, fontSize: 33, height: 1.25),
          ),
          heading2: TextBlockTheme(
            spacing: const VerticalSpacing.zero(),
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: FontSize.xxLarge.size,
                height: 1.25),
          ),
          heading3: TextBlockTheme(
            spacing: const VerticalSpacing.zero(),
            style: Theme.of(context).textTheme.bodyText2.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: FontSize.xLarge.size,
                height: 1.25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.composeMode == ComposeMode.newPost)
              Container(
                  height: 37,
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: <Widget>[
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              child: SizedBox(
                            height: displayHeight(context) / 2,
                            child: _TagSelectDialog(
                              onTagSelect: (tag, channelId) {
                                Navigator.of(context).pop();
                                FocusScope.of(context)
                                    .requestFocus(_currentFocusNode);
                                setState(() {
                                  _tag = tag;
                                  _channelId = channelId;
                                });
                              },
                            ),
                          ))
                        ],
                        child: Chip(
                          label: Text('#${_tag.name}',
                              strutStyle: const StrutStyle(height: 1.25),
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                          backgroundColor: _tag.color,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: TextField(
                          style: const TextStyle(fontSize: 14),
                          strutStyle: const StrutStyle(height: 1.25),
                          controller: _titleFieldController,
                          focusNode: _titleFocusNode,
                          decoration: InputDecoration(
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              labelText: '標題',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 6.8)),
                          onChanged: (value) {
                            setState(() {
                              _title = value;
                            });
                          },
                        ),
                      )
                    ],
                  ))
            else
              const SizedBox(),
            if (widget.composeMode == ComposeMode.quotedReply)
              ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: displayHeight(context) / 4),
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: StyledHtmlView(
                    htmlString: HKGaldenHtmlParser().replyWithQuotes(
                        widget.parentReply,
                        StoreProvider.of<AppState>(context)),
                    floor: widget.parentReply.floor,
                  ),
                ),
              )
            else
              const SizedBox(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ZefyrEditor(
                  controller: _controller,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.none,
                  expands: true,
                  autofocus: true,
                  keyboardAppearance: Brightness.dark,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ZefyrToolbar(
                children: [
                  ToggleStyleButton(
                      attribute: NotusAttribute.bold,
                      icon: Icons.format_bold,
                      controller: _controller),
                  ToggleStyleButton(
                      attribute: NotusAttribute.italic,
                      icon: Icons.format_italic,
                      controller: _controller),
                  ToggleStyleButton(
                    attribute: NotusAttribute.underline,
                    icon: Icons.format_underline,
                    controller: _controller,
                  ),
                  ToggleStyleButton(
                      attribute: NotusAttribute.strikethrough,
                      icon: Icons.format_strikethrough,
                      controller: _controller),
                  VerticalDivider(
                      indent: 16, endIndent: 16, color: Colors.grey.shade400),
                  ToggleStyleButton(
                    attribute: NotusAttribute.h1,
                    icon: CustomIcons.formatHeader1,
                    controller: _controller,
                  ),
                  ToggleStyleButton(
                      attribute: NotusAttribute.h2,
                      icon: CustomIcons.formatHeader2,
                      controller: _controller),
                  ToggleStyleButton(
                      attribute: NotusAttribute.h3,
                      icon: CustomIcons.formatHeader3,
                      controller: _controller),
                  VerticalDivider(
                      indent: 16, endIndent: 16, color: Colors.grey.shade400),
                  LinkStyleButton(controller: _controller)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _getZefyrEditorContent() {
    final content = _controller.document.toDelta();
    return json.encode(content);
  }

  Future<void> _createThread(BuildContext context) async {
    HKGaldenApi()
        .createThread(
            _title,
            [_tag.id],
            await DeltaJsonParser().toGaldenHtml(
                json.decode(_getZefyrEditorContent()) as List<dynamic>))
        .then((threadId) {
      setState(() {
        _isSending = false;
        if (threadId != null) {
          Navigator.pop(context);
          widget.onCreateThread(_channelId);
        } else {
          Scaffold.of(context)
              .showSnackBar(const SnackBar(content: Text('主題發表失敗!')));
        }
      });
    });
  }

  Future<void> _sendReply(BuildContext context) async {
    HKGaldenApi()
        .sendReply(
      widget.threadId,
      await DeltaJsonParser()
          .toGaldenHtml(json.decode(_getZefyrEditorContent()) as List<dynamic>),
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
          Scaffold.of(context)
              .showSnackBar(const SnackBar(content: Text('回覆發送失敗!')));
        }
      });
    });
  }
}

class _TagSelectDialog extends StatelessWidget {
  final Function(Tag, String) onTagSelect;

  const _TagSelectDialog({this.onTagSelect});

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, TagSelectorViewModel>(
        distinct: true,
        converter: (store) => TagSelectorViewModel.create(store),
        builder: (context, viewModel) => SingleChildScrollView(
          //padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: viewModel.channels
                .map((channel) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(channel.channelName,
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(color: Colors.white60)),
                          Wrap(
                            spacing: 8,
                            children: channel.tags
                                .map((tag) => InputChip(
                                      label: Text('#${tag.name}',
                                          strutStyle:
                                              const StrutStyle(height: 1.25),
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
