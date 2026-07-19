import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/ui/thread/reply_position_anchor.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_scroll_physics.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_previous_pull_indicator.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_previous_sliver.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_sliver.dart';

/// Scroll stack for a loaded thread (previous + prefix + center windows).
Widget buildLoadedThreadBody({
  required BuildContext context,
  required ThreadLoaded state,
  required ThreadPageScrollController scrollController,
  required ReplyAnchorRegistry anchorRegistry,
  required GlobalKey footerMeasureKey,
  required ValueListenable<double> previousPullExtent,
  required ValueListenable<double> trailingTopPad,
  required ValueListenable<bool> restoreVisualReady,
  required bool previousPullLoading,
  required bool trailingEdgeLayoutActive,
  required bool pendingRestoreToTrailingEdge,
  required int centerStartIndex,
  required bool Function(OverscrollIndicatorNotification) onOverscrollIndicator,
  required bool Function(ScrollNotification) onScrollNotification,
  required VoidCallback onTrailingMetrics,
  required ThreadReplySuccessCallback onReplySuccess,
}) {
  const Key centerKey = ValueKey('second-sliver-list');

  final allMain = state.thread.replies;
  final List<Reply> prefixReplies = centerStartIndex > 0
      ? allMain.sublist(0, centerStartIndex)
      : const <Reply>[];
  final List<Reply> centerReplies =
      centerStartIndex > 0 ? allMain.sublist(centerStartIndex) : allMain;

  final prefixKeyToBuilderIndex = <Object, int>{
    for (var i = 0; i < prefixReplies.length; i++)
      replyListKey(prefixReplies[i]): prefixReplies.length - i - 1,
  };
  final centerKeyToIndex = <Object, int>{
    for (var i = 0; i < centerReplies.length; i++)
      replyListKey(centerReplies[i]): i,
  };
  final previousKeyToBuilderIndex = <Object, int>{
    for (var i = 0; i < state.previousPages.replies.length; i++)
      replyListKey(state.previousPages.replies[i]):
          state.previousPages.replies.length - i - 1,
  };
  final previousCount = state.previousPages.replies.length;
  final prefixCount = prefixReplies.length;
  final trailingEdge = pendingRestoreToTrailingEdge;
  // Viewport is edge-to-edge; safe area is applied as scroll content insets
  // so layout clears the home indicator / landscape notches.
  final viewPadding = MediaQuery.viewPaddingOf(context);

  return NotificationListener<OverscrollIndicatorNotification>(
    onNotification: onOverscrollIndicator,
    child: NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (trailingEdgeLayoutActive) {
          onTrailingMetrics();
        }
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: onScrollNotification,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            previousPullExtent,
            trailingTopPad,
            restoreVisualReady,
          ]),
          builder: (context, _) {
            final displayExtent = previousPullExtent.value;
            final restoreReady = restoreVisualReady.value;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                ThreadPagePreviousPullIndicator(
                  extent: displayExtent,
                  loading: previousPullLoading,
                ),
                Transform.translate(
                  offset: Offset(0, displayExtent),
                  child: IgnorePointer(
                    ignoring: !restoreReady,
                    child: Opacity(
                      opacity: restoreReady ? 1 : 0,
                      child: CustomScrollView(
                        center: centerKey,
                        controller: scrollController,
                        physics: AlwaysScrollableScrollPhysics(
                          parent: ThreadScrollPhysics(
                            clampLeading: state.currentPage > 1,
                            bounceEnabled: threadScrollBounceEnabled(
                              Theme.of(context).platform,
                            ),
                          ),
                        ),
                        // ignore: deprecated_member_use — ScrollCacheExtent is not exported via material.dart
                        cacheExtent: 2000,
                        slivers: <Widget>[
                          SliverPadding(
                            padding: EdgeInsets.only(
                              left: viewPadding.left,
                              right: viewPadding.right,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return generatePreviousThreadPageSliver(
                                    context,
                                    scrollController,
                                    state,
                                    index,
                                    onReplySuccess,
                                    anchorRegistry,
                                  );
                                },
                                findChildIndexCallback: previousCount == 0
                                    ? null
                                    : (Key key) {
                                        if (key is ValueKey) {
                                          return previousKeyToBuilderIndex[
                                              key.value];
                                        }
                                        return null;
                                      },
                                childCount: previousCount,
                              ),
                            ),
                          ),
                          if (prefixCount > 0)
                            SliverPadding(
                              padding: EdgeInsets.only(
                                left: viewPadding.left,
                                right: viewPadding.right,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final dataIndex =
                                        prefixCount - index - 1;
                                    return generateThreadPageSliver(
                                      context,
                                      scrollController,
                                      state,
                                      prefixReplies,
                                      dataIndex,
                                      onReplySuccess,
                                      anchorRegistry,
                                      isTrailingWindow: false,
                                      footerMeasureKey: null,
                                    );
                                  },
                                  findChildIndexCallback: (Key key) {
                                    if (key is ValueKey) {
                                      return prefixKeyToBuilderIndex[
                                          key.value];
                                    }
                                    return null;
                                  },
                                  childCount: prefixCount,
                                ),
                              ),
                            ),
                          if (trailingEdge)
                            SliverToBoxAdapter(
                              key: centerKey,
                              child: SizedBox(height: trailingTopPad.value),
                            ),
                          // Bottom inset in scroll extent: paints edge-to-edge
                          // while last items clear the home indicator.
                          // centerKey must stay on a direct CustomScrollView child.
                          SliverPadding(
                            key: trailingEdge ? null : centerKey,
                            padding: EdgeInsets.only(
                              left: viewPadding.left,
                              right: viewPadding.right,
                              bottom: viewPadding.bottom,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return generateThreadPageSliver(
                                    context,
                                    scrollController,
                                    state,
                                    centerReplies,
                                    index,
                                    onReplySuccess,
                                    anchorRegistry,
                                    isTrailingWindow: true,
                                    footerMeasureKey: footerMeasureKey,
                                  );
                                },
                                findChildIndexCallback: (Key key) {
                                  if (key is ValueKey) {
                                    return centerKeyToIndex[key.value];
                                  }
                                  return null;
                                },
                                childCount: centerReplies.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!restoreReady)
                  const Positioned.fill(
                    child: ThreadPageLoadingSkeleton(),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
