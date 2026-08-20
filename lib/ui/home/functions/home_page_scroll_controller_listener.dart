part of '../home_page.dart';

const double _kThreadListLoadMoreThreshold = 480;

extension on HomePageState {
  void _initListener() {
    final threadListBloc = BlocProvider.of<ThreadListCubit>(context);
    _threadListSubscription = threadListBloc.stream.listen((state) {
      if (!_loadMoreInFlight) {
        return;
      }
      if (state is ThreadListAppending) {
        return;
      }
      if (state is ThreadListLoaded || state is ThreadListError) {
        _loadMoreInFlight = false;
      }
    });
    _scrollController.addListener(
      () {
        final position = _scrollController.position;
        if (!position.hasContentDimensions) {
          return;
        }
        if (position.pixels <
            position.maxScrollExtent - _kThreadListLoadMoreThreshold) {
          return;
        }
        if (_loadMoreInFlight) {
          return;
        }
        final state = threadListBloc.state;
        if (state is! ThreadListLoaded || state is ThreadListAppending) {
          return;
        }
        _loadMoreInFlight = true;
        threadListBloc.load(
          channelId: state.currentChannelId,
          page: state.currentPage + 1,
        );
      },
    );
  }
}
