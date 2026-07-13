part of '../compose_page.dart';

class _RichTextEditor extends StatefulWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final Future<String> Function(File)? imagePickCallback;

  const _RichTextEditor({
    required this.controller,
    required this.focusNode,
    this.imagePickCallback,
  });

  @override
  State<_RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<_RichTextEditor> {
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              embedBuilders: [
                _ImageEmbedBuilder(),
              ],
            ),
          ),
        ),
        _RichTextToolbar(
          controller: widget.controller,
          imagePickCallback: widget.imagePickCallback,
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
