import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_cubit.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview.dart';

typedef ThreadReplySuccessCallback = void Function(
  BuildContext context,
  ThreadWebViewController webView,
  Reply reply,
  bool onLastPage,
);

void onThreadReplySuccess(
  BuildContext context,
  ThreadWebViewController webView,
  Reply reply,
  bool onLastPage,
) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('回覆發送成功!')));
  if (onLastPage) {
    BlocProvider.of<ThreadCubit>(context).appendReply(reply);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      webView.scrollToBottom();
    });
  }
}
