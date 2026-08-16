import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/galden_fab_hero.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_on_reply_success.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

Widget buildThreadPageFab(
  BuildContext context,
  ThreadWebViewController webView,
  ThreadPageArguments arguments,
  ThreadReplySuccessCallback onReplySuccess,
) {
  return galdenFabHero(
    child: FloatingActionButton(
      heroTag: null,
      onPressed: () => !BlocProvider.of<ThreadPageCubit>(context).state.canReply
          ? showCustomAlert(
              context: context,
              title: '未登入',
              content: '請先登入',
            )
          : showBarModalBottomSheet(
              duration: const Duration(milliseconds: 300),
              animationCurve: Curves.easeOut,
              context: context,
              builder: (context) => ComposePage(
                composeMode: ComposeMode.reply,
                threadId: arguments.threadId,
                onSent: (reply) {
                  onReplySuccess(
                    context,
                    webView,
                    reply,
                    BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
                  );
                },
              ),
            ),
      child: const Icon(Icons.reply_rounded),
    ),
  );
}
