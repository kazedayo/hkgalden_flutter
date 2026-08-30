import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/quote_preview_webview.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

import 'package:hkgalden_flutter/bloc/compose/compose_cubit.dart';
import 'package:hkgalden_flutter/bloc/compose/compose_state.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/models/smiley.dart';
import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/networking/image_upload_api.dart';
import 'package:hkgalden_flutter/utils/smiley_embed.dart';

part 'widgets/rich_text_toolbar.dart';
part 'widgets/rich_text_editor.dart';
part 'widgets/smiley_pane.dart';

enum ComposeMode {
  newPost,
  reply,
  quotedReply,
}

Future<T?> showComposeSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: builder,
    ),
  );
}

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
  late QuillController _controller;
  late TextEditingController _titleFieldController;
  late FocusNode _focusNode;
  late FocusNode _titleFocusNode;

  String? _cachedQuoteHtml;
  List<SmileyPack> _smileyPacks = const [];
  bool _imageUploading = false;

  @override
  void initState() {
    _tag = const Tag(id: '02NP3MVYm', name: '吹水', color: Color(0xff457cb0));
    _channelId = '';
    _controller = QuillController.basic();
    _titleFieldController = TextEditingController();
    _focusNode = FocusNode();
    _titleFocusNode = FocusNode();
    super.initState();
    final api = context.read<HKGaldenApi>();
    _smileyPacks = api.cachedPacks;
    _loadSmileyPacks(api);
  }

  Future<void> _loadSmileyPacks(HKGaldenApi api) async {
    try {
      final packs = await api.getInstalledPacks();
      if (!mounted || packs == null || identical(packs, _smileyPacks)) {
        return;
      }
      setState(() => _smileyPacks = packs);
    } catch (_) {
      // Unauthenticated / missing provider: empty packs, picker stays hidden.
    }
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
    final sessionUserCubit = BlocProvider.of<SessionUserCubit>(context);
    return BlocProvider(
      create: (context) => ComposeCubit(
        api: RepositoryProvider.of<HKGaldenApi>(context),
      ),
      child: BlocConsumer<ComposeCubit, ComposeState>(
        listenWhen: (prev, next) =>
            next is ComposeSuccess || next is ComposeFailure,
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
        buildWhen: (prev, next) {
          final wasSending = prev is ComposeSending;
          final isSending = next is ComposeSending;
          return wasSending != isSending;
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
              leading: const CloseButton(),
              actions: <Widget>[
                Visibility(
                  visible: isSending,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: ProgressSpinner(),
                  ),
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: isSending
                        ? null
                        : () {
                            if (widget.composeMode == ComposeMode.newPost) {
                              final title = _titleFieldController.text;
                              if (title.isEmpty ||
                                  _controller.document.toString() == '/n') {
                                showCustomAlert(
                                  context: context,
                                  title: '注意!',
                                  content: '內文/標題不能為空',
                                );
                                return;
                              }
                              context.read<ComposeCubit>().createThread(
                                  title, _tag.id!, _getZefyrEditorContent());
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
                if (_imageUploading)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        const ProgressSpinner(),
                        const SizedBox(width: 8),
                        Text(
                          '圖片上載中...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
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
                                height: MediaQuery.sizeOf(context).height / 3,
                                child: _TagSelectDialog(
                                  channels: (BlocProvider.of<ChannelCubit>(
                                              context)
                                          .state as ChannelLoaded)
                                      .channels,
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
                                    .withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSmall)),
                                hintText: '標題',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 10)),
                          ),
                        )
                      ],
                    ),
                  )
                else
                  const SizedBox(),
                if (widget.composeMode == ComposeMode.quotedReply)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height / 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: QuotePreviewWebView(
                        html: _quoteHtml(sessionUserCubit),
                      ),
                    ),
                  )
                else
                  const SizedBox(),
                Expanded(
                  child: Builder(builder: (builderContext) {
                    return _RichTextEditor(
                      controller: _controller,
                      focusNode: _focusNode,
                      imagePickCallback: (file) =>
                          _onImagePickCallback(builderContext, file),
                      smileyPacks: _smileyPacks,
                    );
                  }),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  String _quoteHtml(SessionUserCubit sessionUserCubit) {
    return _cachedQuoteHtml ??= HKGaldenHtmlParser().replyWithQuotes(
        widget.parentReply!, sessionUserCubit.state as SessionUserLoaded)!;
  }

  String _getZefyrEditorContent() {
    final content = _controller.document.toDelta();
    return json.encode(content);
  }

  Future<String> _onImagePickCallback(BuildContext context, File file) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _imageUploading = true);
    return uploadImage(file.path).then((value) {
      if (mounted) {
        setState(() => _imageUploading = false);
      }
      return value;
    }).catchError((error) {
      if (mounted) {
        setState(() => _imageUploading = false);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('圖片上載失敗')),
        );
      }
      return '';
    });
  }
}

class _TagSelectDialog extends StatelessWidget {
  final List<Channel> channels;
  final Function(Tag, String) onTagSelect;

  const _TagSelectDialog({required this.channels, required this.onTagSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: channels
            .map(
              (channel) => Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(channel.channelName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.white60)),
                    Wrap(
                      spacing: 8,
                      children: channel.tags
                          .map(
                            (tag) => InputChip(
                              label: Text('#${tag.name}',
                                  strutStyle: const StrutStyle(height: 1.25),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700)),
                              backgroundColor: tag.color,
                              side: BorderSide.none,
                              onPressed: () {
                                onTagSelect(tag, channel.channelId);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
