import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/thread_page_state.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_header.dart';

class ThreadPageFooter extends StatelessWidget {
  const ThreadPageFooter({super.key, this.measureKey});

  final GlobalKey? measureKey;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ThreadPageCubit, ThreadPageState>(
        buildWhen: (prev, next) => prev.onLastPage != next.onLastPage,
        builder: (context, pageState) {
          return BlocBuilder<ThreadBloc, ThreadState>(
            buildWhen: (prev, state) {
              if ((prev is ThreadLoaded && state is ThreadAppending) ||
                  (prev is ThreadAppending && state is ThreadLoaded)) {
                return true;
              } else {
                return false;
              }
            },
            builder: (context, state) => KeyedSubtree(
              key: measureKey,
              child: !pageState.onLastPage
                  ? ThreadPageLoadingSkeletonHeader()
                  : SizedBox(
                      height: 85,
                      child: Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            visualDensity: VisualDensity.comfortable,
                          ),
                          clipBehavior: Clip.hardEdge,
                          onPressed: () {
                            if (state is ThreadLoaded) {
                              BlocProvider.of<ThreadBloc>(context).add(
                                RequestThreadEvent(
                                  threadId: state.thread.threadId,
                                  page: state.endPage,
                                  isInitialLoad: false,
                                ),
                              );
                            }
                          },
                          icon: state is ThreadAppending
                              ? const ProgressSpinner()
                              : const Icon(
                                  Icons.refresh,
                                  size: 25,
                                  color: Colors.grey,
                                ),
                          label: Text(
                            state is ThreadAppending ? '撈緊...' : '重新整理',
                            style: Theme.of(context).textTheme.bodySmall,
                            strutStyle: const StrutStyle(
                              height: 1.1,
                              forceStrutHeight: true,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      );
}
