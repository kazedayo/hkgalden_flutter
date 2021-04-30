part of '../compose_page.dart';

List<Widget> _buildQuillEditor(
        BuildContext context,
        QuillController _controller,
        FocusNode _focusNode,
        Future<String> Function(File) imageCallback) =>
    [
      Expanded(
        child: QuillEditor(
          controller: _controller,
          focusNode: _focusNode,
          autoFocus: true,
          textCapitalization: TextCapitalization.none,
          expands: true,
          keyboardAppearance: Brightness.dark,
          scrollable: true,
          scrollController: ScrollController(),
          padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
          readOnly: false,
          customStyles: DefaultStyles(
              h1: DefaultTextBlockStyle(
                  Theme.of(context).textTheme.bodyText2!.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: 33,
                      height: 1.25),
                  const Tuple2(0.0, 0.0),
                  const Tuple2(0.0, 0.0),
                  null),
              h2: DefaultTextBlockStyle(
                  Theme.of(context).textTheme.bodyText2!.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: FontSize.xxLarge.size,
                      height: 1.25),
                  const Tuple2(0.0, 0.0),
                  const Tuple2(0.0, 0.0),
                  null),
              h3: DefaultTextBlockStyle(
                  Theme.of(context).textTheme.bodyText2!.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: FontSize.xLarge.size,
                      height: 1.25),
                  const Tuple2(0.0, 0.0),
                  const Tuple2(0.0, 0.0),
                  null),
              strikeThrough:
                  const TextStyle(decoration: TextDecoration.lineThrough),
              paragraph: DefaultTextBlockStyle(
                  Theme.of(context).textTheme.bodyText2!.copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: FontSize.large.size,
                      height: 1.25),
                  const Tuple2(0.0, 0.0),
                  const Tuple2(0.0, 0.0),
                  null)),
        ),
      ),
      QuillToolbar.basic(
        controller: _controller,
        showHistory: false,
        showBackgroundColorButton: false,
        showColorButton: false,
        showCodeBlock: false,
        showListCheck: false,
        showIndent: false,
        showQuote: false,
        onImagePickCallback: imageCallback,
      ),
    ];
