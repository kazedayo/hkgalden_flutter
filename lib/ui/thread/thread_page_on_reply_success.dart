import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';

void onThreadReplySuccess(
  BuildContext context,
  ScrollController scrollController,
  Reply reply,
  bool onLastPage,
) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('回覆發送成功!')));
  if (onLastPage) {
    BlocProvider.of<ThreadBloc>(context)
        .add(AppendReplyToThreadEvent(reply: reply));
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }
}
