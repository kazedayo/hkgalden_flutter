part of '../thread_page.dart';

void _initListener(
    ThreadPageArguments arguments,
    ThreadBloc threadBloc,
    ScrollController scrollController,
    Function() lastPageCallback,
    Function(bool) fabCallback,
    Function(double) elevationCallback) {
  scrollController.addListener(() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      lastPageCallback();
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
    if (scrollController.position.userScrollDirection ==
            ScrollDirection.forward ||
        scrollController.position.pixels ==
            scrollController.position.maxScrollExtent) {
      fabCallback(false);
    } else if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      fabCallback(true);
    }
    final double newElevation = scrollController.position.pixels >
            scrollController.position.minScrollExtent
        ? 4.0
        : 0.0;
    elevationCallback(newElevation);
  });
}
