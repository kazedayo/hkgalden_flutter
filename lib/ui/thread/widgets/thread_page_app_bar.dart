import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/models/ui_state_models/thread_page_state.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

PreferredSizeWidget buildThreadPageAppBar(
  BuildContext context,
  ThreadPageArguments arguments,
) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: BlocBuilder<ThreadPageCubit, ThreadPageState>(
      buildWhen: (prev, next) => prev.elevation != next.elevation,
      builder: (context, state) => AppBar(
        elevation: state.elevation,
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
