part of '../thread_page.dart';

class _PageFooter extends StatelessWidget {
  final bool onLastPage;

  const _PageFooter({
    required this.onLastPage,
  });

  @override
  Widget build(BuildContext context) => BlocBuilder<ThreadBloc, ThreadState>(
        buildWhen: (prev, state) {
          if ((prev is ThreadLoaded && state is ThreadAppending) ||
              (prev is ThreadAppending && state is ThreadLoaded)) {
            return true;
          } else {
            return false;
          }
        },
        builder: (context, state) => SafeArea(
          top: false,
          child: !onLastPage
              ? ThreadPageLoadingSkeletonHeader()
              : Column(
                  children: [
                    SizedBox(
                      height: 85,
                      child: Center(
                        child: TextButton.icon(
                            style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                visualDensity: VisualDensity.comfortable),
                            clipBehavior: Clip.hardEdge,
                            onPressed: () {
                              if (state is ThreadLoaded) {
                                BlocProvider.of<ThreadBloc>(context).add(
                                    RequestThreadEvent(
                                        threadId: state.thread.threadId,
                                        page: state.endPage,
                                        isInitialLoad: false));
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
                                  height: 1.1, forceStrutHeight: true),
                            )),
                      ),
                    ),
                  ],
                ),
        ),
      );
}
