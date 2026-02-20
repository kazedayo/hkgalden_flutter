part of '../compose_page.dart';

// ignore: unused_element
Widget _buildQuillEditor(
  BuildContext context,
  QuillController controller,
  FocusNode focusNode,
  Future<String> Function(File) imageCallback,
) =>
    _RichTextEditor(
      controller: controller,
      focusNode: focusNode,
      imagePickCallback: imageCallback,
    );
