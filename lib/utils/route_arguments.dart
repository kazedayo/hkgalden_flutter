import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';

class ThreadPageArguments {
  final String title;
  final int threadId;
  final int page;
  final bool locked;

  final int? floor;

  ThreadPageArguments(
      {required this.title,
      required this.threadId,
      required this.page,
      required this.locked,
      this.floor});
}

class ComposePageArguments {
  final ComposeMode composeMode;
  final int? threadId;
  final Reply? parentReply;
  final Function(Reply)? onSent;
  final Function(String)? onCreateThread;

  ComposePageArguments(
      {required this.composeMode,
      this.threadId,
      this.parentReply,
      this.onSent,
      this.onCreateThread});
}
