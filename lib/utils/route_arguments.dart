import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';

class ThreadPageArguments {
  final String title;
  final int threadId;
  final int page;

  ThreadPageArguments({this.title, this.threadId, this.page});
}

class ComposePageArguments {
  final ComposeMode composeMode;
  final int threadId;
  final Reply parentReply;
  final Function(Reply) onSent;
  final Function(String) onCreateThread;

  ComposePageArguments(
      {this.composeMode,
      this.threadId,
      this.parentReply,
      this.onSent,
      this.onCreateThread});
}
