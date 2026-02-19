part of '../compose_page.dart';

/// A self-contained WYSIWYG rich text editor that combines a [QuillEditor]
/// with a custom [_RichTextToolbar].
///
/// Accepts a [QuillController] and [FocusNode] that are owned by the parent,
/// so the parent can still read the document content on submit.
///
/// Supported formatting: Bold, Italic, Underline, Strikethrough,
/// Center/Right alignment, H1/H2/H3, and hyperlinks.
class _RichTextEditor extends StatelessWidget {
  final QuillController controller;
  final FocusNode focusNode;

  const _RichTextEditor({
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: QuillEditor(
            controller: controller,
            focusNode: focusNode,
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              autoFocus: true,
              expands: true,
              scrollable: true,
              padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
              customStyles: _buildEditorStyles(context),
              customStyleBuilder: (attribute) =>
                  _getCustomStyle(context, attribute),
            ),
          ),
        ),
        _RichTextToolbar(controller: controller),
      ],
    );
  }

  /// Builds [DefaultStyles] that match the app's current theme.
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
