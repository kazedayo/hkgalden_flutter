part of '../compose_page.dart';

List<Widget> _buildQuillEditor(BuildContext context, QuillController controller,
        FocusNode focusNode, Future<String> Function(File) imageCallback) =>
    [
      Expanded(
        child: QuillEditor.basic(
          controller: controller,
          focusNode: focusNode,
          config: QuillEditorConfig(
            autoFocus: true,
            expands: true,
            scrollable: true,
            padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
            customStyles: DefaultStyles(
                h1: DefaultTextBlockStyle(
                    Theme.of(context).textTheme.headlineMedium!,
                    HorizontalSpacing.zero,
                    const VerticalSpacing(0.0, 0.0),
                    const VerticalSpacing(0.0, 0.0),
                    null),
                h2: DefaultTextBlockStyle(
                    Theme.of(context).textTheme.titleLarge!,
                    HorizontalSpacing.zero,
                    const VerticalSpacing(0.0, 0.0),
                    const VerticalSpacing(0.0, 0.0),
                    null),
                h3: DefaultTextBlockStyle(
                    Theme.of(context).textTheme.titleMedium!,
                    HorizontalSpacing.zero,
                    const VerticalSpacing(0.0, 0.0),
                    const VerticalSpacing(0.0, 0.0),
                    null),
                strikeThrough:
                    const TextStyle(decoration: TextDecoration.lineThrough),
                paragraph: DefaultTextBlockStyle(
                    Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 16),
                    HorizontalSpacing.zero,
                    const VerticalSpacing(0.0, 0.0),
                    const VerticalSpacing(0.0, 0.0),
                    null)),
          ),
        ),
      ),
      QuillSimpleToolbar(
        controller: controller,
        config: QuillSimpleToolbarConfig(
          showBackgroundColorButton: false,
          showColorButton: false,
          showCodeBlock: false,
          showListCheck: false,
          showIndent: false,
          showQuote: false,
        ),
      ),
    ];
