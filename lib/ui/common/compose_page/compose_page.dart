import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/networking/image_upload_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';

part 'widgets/compose_page_tag_select_dialog.dart';
part 'widgets/quill_editor.dart';

class ComposePage extends StatefulWidget {
  final ComposeMode composeMode;
  final int? threadId;
  final Reply? parentReply;
  final Function(Reply)? onSent;
  final Function(String)? onCreateThread;

  const ComposePage(
      {super.key,
      required this.composeMode,
      this.threadId,
      this.parentReply,
      this.onSent,
      this.onCreateThread});

  @override
  ComposePageState createState() => ComposePageState();
}

class ComposePageState extends State<ComposePage> {
  late Tag _tag;
  late String _channelId;
  late String _title;
  late QuillController _controller;
  late TextEditingController _titleFieldController;
  late FocusNode _focusNode;
  late FocusNode _titleFocusNode;
  late FocusNode _currentFocusNode;
  late bool _isSending;

  @override
  void initState() {
    //default to tag '吹水'
    _tag = const Tag(id: '02NP3MVYm', name: '吹水', color: Color(0xff457cb0));
    _channelId = '';
    _title = '';
    _controller = QuillController.basic();
    _titleFieldController = TextEditingController();
    _focusNode = FocusNode();
    _titleFocusNode = FocusNode();
    _isSending = false;
    _focusNode.addListener(() {
      _focusListener(_focusNode);
    });
    _titleFocusNode.addListener(() {
      _focusListener(_titleFocusNode);
    });
    super.initState();
  }

  void _focusListener(FocusNode node) {
    if (node.hasFocus) {
      _currentFocusNode = node;
    }
    if (!_focusNode.hasFocus && !_titleFocusNode.hasFocus) {
      _retainFocus();
    }
  }

  void _retainFocus() {
    FocusScope.of(context).requestFocus(_currentFocusNode);
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
    final sessionUserBloc = BlocProvider.of<SessionUserBloc>(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle:
            Theme.of(context).platform == TargetPlatform.iOS ? true : false,
        title: Text(
          widget.composeMode == ComposeMode.newPost
              ? '發表主題'
              : widget.composeMode == ComposeMode.reply
                  ? '回覆主題'
                  : '引用回覆 (#${widget.parentReply!.floor})',
          style: Theme.of(context)
              .textTheme
              .titleMedium!
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
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.composeMode == ComposeMode.newPost)
            Container(
              height: 29,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: <Widget>[
                  Theme(
                    data: Theme.of(context).copyWith(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent),
                    child: PopupMenuButton(
                      offset: const Offset(0, -48),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                            child: SizedBox(
                          height: displayHeight(context) / 3,
                          child: _TagSelectDialog(
                            onTagSelect: (tag, channelId) {
                              Navigator.of(context).pop();
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
                                .bodySmall!
                                .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                        backgroundColor: _tag.color,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: TextField(
                      style: Theme.of(context).textTheme.bodyMedium,
                      strutStyle: const StrutStyle(height: 1.25),
                      controller: _titleFieldController,
                      focusNode: _titleFocusNode,
                      decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.never,
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
              ),
            )
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
                      widget.parentReply!,
                      sessionUserBloc.state as SessionUserLoaded)!,
                  floor: widget.parentReply!.floor,
                ),
              ),
            )
          else
            const SizedBox(),
          ..._buildQuillEditor(
              context, _controller, _focusNode, onImagePickCallback)
        ],
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
            [_tag.id!],
            await DeltaJsonParser().toGaldenHtml(
                json.decode(_getZefyrEditorContent()) as List<dynamic>))
        .then((threadId) {
      setState(() {
        _isSending = false;
        if (threadId != null) {
          widget.onCreateThread!(_channelId);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('主題發表失敗!')));
        }
      });
    });
  }

  Future<String> onImagePickCallback(File file) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: Row(
          children: const [
            ProgressSpinner(),
            SizedBox(
              width: 8,
            ),
            Text('圖片上載中...')
          ],
        ),
      ),
    );
    return ImageUploadApi().uploadImage(file.path).then((value) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      return value;
    });
  }

  Future<void> _sendReply(BuildContext context) async {
    HKGaldenApi()
        .sendReply(
      widget.threadId!,
      await DeltaJsonParser()
          .toGaldenHtml(json.decode(_getZefyrEditorContent()) as List<dynamic>),
      parentId: widget.composeMode == ComposeMode.quotedReply
          ? widget.parentReply!.replyId
          : '',
    )
        .then((sentReply) {
      setState(() {
        _isSending = false;
        if (sentReply != null) {
          widget.onSent!(sentReply);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('回覆發送失敗!')));
        }
      });
    });
  }
}
