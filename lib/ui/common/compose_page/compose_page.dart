import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/action_bar_spinner.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';

import 'package:hkgalden_flutter/bloc/cubit/compose_cubit.dart';
import 'package:hkgalden_flutter/bloc/cubit/compose_state.dart';
import 'package:hkgalden_flutter/bloc/cubit/url_validation_cubit.dart';

part 'widgets/compose_page_tag_select_dialog.dart';
part 'widgets/quill_editor.dart';
part 'widgets/toolbar_button.dart';
part 'widgets/link_dialog.dart';
part 'widgets/image_insert_dialog.dart';
part 'widgets/rich_text_toolbar.dart';
part 'widgets/rich_text_editor.dart';

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
    final sessionUserBloc = BlocProvider.of<SessionUserBloc>(context);
    return BlocProvider(
      create: (context) => ComposeCubit(),
      child: BlocConsumer<ComposeCubit, ComposeState>(
        listener: (context, state) {
          if (state is ComposeSuccess) {
            if (widget.composeMode == ComposeMode.newPost) {
              widget.onCreateThread!(_channelId);
            } else {
              widget.onSent!(state.result);
            }
            Navigator.pop(context);
          } else if (state is ComposeFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isSending = state is ComposeSending;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              centerTitle: Theme.of(context).platform == TargetPlatform.iOS
                  ? true
                  : false,
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
                ActionBarSpinner(isVisible: isSending),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: isSending
                        ? null
                        : () {
                            if (widget.composeMode == ComposeMode.newPost) {
                              if (_title == '' ||
                                  _controller.document.toString() == '/n') {
                                showCustomDialog(
                                  context: context,
                                  builder: (context) => const CustomAlertDialog(
                                      title: '注意!', content: '內文/標題不能為空'),
                                );
                                return;
                              }
                              context.read<ComposeCubit>().createThread(
                                  _title, _tag.id!, _getZefyrEditorContent());
                            } else {
                              context.read<ComposeCubit>().sendReply(
                                  widget.threadId!, _getZefyrEditorContent(),
                                  parentId: widget.composeMode ==
                                          ComposeMode.quotedReply
                                      ? widget.parentReply!.replyId
                                      : null);
                            }
                          },
                  ),
                ),
              ],
            ),
            body: Column(
              children: <Widget>[
                if (widget.composeMode == ComposeMode.newPost)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Theme(
                          data: Theme.of(context).copyWith(
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent),
                          child: PopupMenuButton(
                            offset: const Offset(-14, -8),
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
                            child: ThreadTagChip(
                              label: _tag.name,
                              backgroundColor: _tag.color,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            style: Theme.of(context).textTheme.bodyMedium,
                            controller: _titleFieldController,
                            focusNode: _titleFocusNode,
                            decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.5),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(8)),
                                hintText: '標題',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 10)),
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
                Expanded(
                  child: Builder(builder: (builderContext) {
                    return _buildQuillEditor(
                        builderContext,
                        _controller,
                        _focusNode,
                        (file) => _onImagePickCallback(builderContext, file));
                  }),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  String _getZefyrEditorContent() {
    final content = _controller.document.toDelta();
    return json.encode(content);
  }

  Future<String> _onImagePickCallback(BuildContext context, File file) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
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
    // Use the cubit to trigger upload
    return context.read<ComposeCubit>().uploadImage(file.path).then((value) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
      }
      return value;
    }).catchError((error) {
      if (mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('圖片上載失敗')),
        );
      }
      return '';
    });
  }
}
