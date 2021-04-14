part of '../thread_page.dart';

void _initListener(
  ThreadPageArguments arguments,
  ThreadBloc threadBloc,
  ScrollController scrollController,
  ThreadPageCubit cubit,
) {
  scrollController.addListener(() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      if (!cubit.state.onLastPage) {
        threadBloc.add(RequestThreadEvent(
            threadId: (threadBloc.state as ThreadLoaded).thread.threadId,
            page: (threadBloc.state as ThreadLoaded).currentPage + 1,
            isInitialLoad: false));
      }
    } else if (scrollController.position.pixels ==
        scrollController.position.minScrollExtent) {
      if ((threadBloc.state as ThreadLoaded).currentPage != 1 &&
          (threadBloc.state as ThreadLoaded).endPage <= arguments.page) {
        threadBloc.add(RequestThreadEvent(
            threadId: (threadBloc.state as ThreadLoaded).thread.threadId,
            page: (threadBloc.state as ThreadLoaded).currentPage - 1,
            isInitialLoad: false));
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
