part of '../thread_page.dart';

void _initListener(
  ThreadPageArguments arguments,
  ThreadBloc threadBloc,
  ScrollController scrollController,
  ThreadPageCubit cubit,
) {
  scrollController.addListener(() {
    final state = threadBloc.state;
    if (state is ThreadLoaded) {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (!cubit.state.onLastPage) {
          threadBloc.add(RequestThreadEvent(
              threadId: state.thread.threadId,
              page: state.currentPage + 1,
              isInitialLoad: false));
        }
      } else if (scrollController.position.pixels ==
          scrollController.position.minScrollExtent) {
        if (state.currentPage != 1) {
          threadBloc.add(RequestThreadEvent(
              threadId: state.thread.threadId,
              page: state.currentPage - 1,
              isInitialLoad: false));
        }
      }
    }
    final double newElevation = scrollController.position.pixels >
            scrollController.position.minScrollExtent
        ? 4.0
        : 0.0;
    if (newElevation != cubit.state.elevation) {
      cubit.setElevation(newElevation);
    }
  });
}
