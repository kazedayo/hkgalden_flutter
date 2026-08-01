part of '../compose_page.dart';

class _RichTextEditor extends StatefulWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final Future<String> Function(File)? imagePickCallback;
  final List<SmileyPack> smileyPacks;

  const _RichTextEditor({
    required this.controller,
    required this.focusNode,
    this.imagePickCallback,
    this.smileyPacks = const [],
  });

  @override
  State<_RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<_RichTextEditor> {
  late final ScrollController _scrollController = ScrollController();

  /// When true, the smiley panel replaces the system soft keyboard.
  bool _smileyKeyboardOpen = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setSmileyKeyboardOpen(bool open) {
    if (_smileyKeyboardOpen == open) return;

    // Quill skips the platform text-input connection when readOnly is true,
    // so the system keyboard stays hidden while the smiley panel is active.
    // Programmatic replaceText (smiley insert) still works. Rebuild so Quill
    // re-reads controller.readOnly and opens/closes the IME connection.
    widget.controller.readOnly = open;
    setState(() => _smileyKeyboardOpen = open);

    if (open) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      if (!widget.focusNode.hasFocus) {
        widget.focusNode.requestFocus();
      }
    } else {
      // Ensure focus so Quill re-attaches the IME after leaving readOnly.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.focusNode.requestFocus();
      });
    }
  }

  void _toggleSmileyKeyboard() {
    _setSmileyKeyboardOpen(!_smileyKeyboardOpen);
  }

  /// Tapping the editor while the smiley keyboard is open switches back to
  /// the system keyboard (standard custom-keyboard UX).
  bool _onEditorTapUp(
    TapUpDetails details,
    TextPosition Function(Offset offset) getPosition,
  ) {
    if (_smileyKeyboardOpen) {
      _setSmileyKeyboardOpen(false);
    }
    return false; // let Quill handle selection placement
  }

  @override
  Widget build(BuildContext context) {
    final canShowSmiley =
        widget.smileyPacks.isNotEmpty && _smileyKeyboardOpen;

    return Column(
      children: [
        Expanded(
          child: QuillEditor(
            controller: widget.controller,
            focusNode: widget.focusNode,
            scrollController: _scrollController,
            config: QuillEditorConfig(
              autoFocus: true,
              expands: true,
              scrollable: true,
              padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
              customStyles: _buildEditorStyles(context),
              customStyleBuilder: (attribute) =>
                  _getCustomStyle(context, attribute),
              onTapUp: _onEditorTapUp,
              embedBuilders: [
                _ImageEmbedBuilder(),
                _SmileyEmbedBuilder(),
              ],
            ),
          ),
        ),
        _RichTextToolbar(
          controller: widget.controller,
          imagePickCallback: widget.imagePickCallback,
          showSmileyButton: widget.smileyPacks.isNotEmpty,
          isSmileyKeyboardOpen: _smileyKeyboardOpen,
          onToggleSmileyKeyboard: _toggleSmileyKeyboard,
          // Bottom safe area only when no smiley keyboard is sitting below.
          applyBottomSafeArea: !canShowSmiley,
        ),
        if (canShowSmiley)
          _SmileyPane(
            controller: widget.controller,
            packs: widget.smileyPacks,
          ),
      ],
    );
  }

  DefaultStyles _buildEditorStyles(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const noSpacing = VerticalSpacing(0.0, 0.0);

    return DefaultStyles(
      strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
      paragraph: DefaultTextBlockStyle(
        textTheme.bodyMedium!.copyWith(fontSize: 16),
        HorizontalSpacing.zero,
        noSpacing,
        noSpacing,
        null,
      ),
    );
  }

  TextStyle _getCustomStyle(BuildContext context, Attribute attribute) {
    final textTheme = Theme.of(context).textTheme;
    if (attribute.key == Attribute.font.key) {
      switch (attribute.value) {
        case 'h1':
          return textTheme.headlineMedium!;
        case 'h2':
          return textTheme.titleLarge!;
        case 'h3':
          return textTheme.titleMedium!;
      }
    }
    return const TextStyle();
  }
}

class _ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final imageUrl = embedContext.node.value.data;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Image(
        image: ResizeImage(
          NetworkImage(imageUrl as String),
          width: (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
              .toInt(),
        ),
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SmileyEmbedBuilder extends EmbedBuilder {
  @override
  String get key => SmileyEmbed.type;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    EmbedContext embedContext,
  ) {
    final raw = embedContext.node.value.data;
    if (raw is! Map) {
      return const SizedBox.shrink();
    }
    final data = Map<String, dynamic>.from(raw);
    final id = data['id']?.toString();
    final packId = data['packId']?.toString();
    if (id == null ||
        id.isEmpty ||
        packId == null ||
        packId.isEmpty) {
      return const SizedBox.shrink();
    }

    final width =
        (data['width'] is num) ? (data['width'] as num).toDouble() : 24.0;
    final height =
        (data['height'] is num) ? (data['height'] as num).toDouble() : 24.0;
    final safeHeight = height > 0 ? height : 24.0;
    final safeWidth = width > 0 ? width : 24.0;
    final displayHeight = safeHeight.clamp(16.0, 48.0);
    final displayWidth =
        (safeWidth * (displayHeight / safeHeight)).clamp(16.0, 64.0);
    final url = smileyGifUrl(packId: packId, smileyId: id);
    final alt = data['alt']?.toString();

    return Image.network(
      url,
      width: displayWidth,
      height: displayHeight,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      semanticLabel: alt,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: displayWidth,
        height: displayHeight,
        child: Icon(
          Icons.emoji_emotions_outlined,
          size: displayHeight * 0.8,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
