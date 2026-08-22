import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_ui.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

PreferredSizeWidget buildThreadPageAppBar(
  BuildContext context,
  ThreadPageArguments arguments,
  ThreadPageUi pageUi,
) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ValueListenableBuilder<double>(
      valueListenable: pageUi.elevation,
      builder: (context, elevation, _) => AppBar(
        elevation: elevation,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Theme.of(context).platform == TargetPlatform.iOS
              ? Icons.arrow_back_ios_rounded
              : Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: SizedBox(
          height: kToolbarHeight * 0.85,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  arguments.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 19),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),
        actions: [
          Visibility(
            visible: arguments.locked,
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.lock_rounded),
            ),
          )
        ],
      ),
    ),
  );
}
