import 'package:flutter/material.dart';

import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/galden_fab_hero.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_on_reply_success.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_ui.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

Widget buildThreadPageFab(
  BuildContext context,
  ThreadWebViewController webView,
  ThreadPageArguments arguments,
  ThreadReplySuccessCallback onReplySuccess,
  ThreadPageUi pageUi,
) {
  return galdenFabHero(
    child: FloatingActionButton(
      heroTag: null,
      onPressed: () => !pageUi.canReply.value
          ? showCustomAlert(
              context: context,
              title: '未登入',
              content: '請先登入',
            )
          : showComposeSheet(
              context: context,
              builder: (context) => ComposePage(
                composeMode: ComposeMode.reply,
                threadId: arguments.threadId,
                onSent: (reply) {
                  onReplySuccess(
                    context,
                    webView,
                    reply,
                    pageUi.onLastPage.value,
                  );
                },
              ),
            ),
      child: const Icon(Icons.reply_rounded),
    ),
  );
}
