import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/utils/html_styles.dart';

void main() {
  group('HtmlStyles theme cache (shipped generate)', () {
    setUp(HtmlStyles.clearCache);

    testWidgets('second generate with same theme returns identical map instance',
        (tester) async {
      late Map<String, Style> first;
      late Map<String, Style> second;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              first = HtmlStyles.generate(context);
              second = HtmlStyles.generate(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(first, second), isTrue,
          reason: 'cached style map should be reused within same theme');
      expect(first.containsKey('blockquote'), isTrue);
      expect(first['blockquote']!.border, isNotNull);
    });

    testWidgets('generate after clearCache allocates a new map', (tester) async {
      late Map<String, Style> first;
      late Map<String, Style> second;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              first = HtmlStyles.generate(context);
              HtmlStyles.clearCache();
              second = HtmlStyles.generate(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(first, second), isFalse);
      expect(second.containsKey('html'), isTrue);
    });
  });

  group('source structure: rebuild boundaries', () {
    late String homePage;
    late String frontLayer;
    late String startup;
    late String styledHtml;
    late String commentCell;
    late String previousSliver;
    late String appBar;
    late String threadPageState;
    late String richTextEditor;
    late String richTextToolbar;
    late String composePage;
    late String homeDrawer;
    late String threadPageFooter;
    late String threadPageSliver;
    late String threadPageScrollListener;
    late String threadPage;
    late String threadPageLoadedBody;
    late String threadPageScrollController;
    late String previousPagePullController;
    late String threadRestoreController;
    late String replyPositionAnchor;
    late String previousPullIndicator;

    /// Combined sources for symbols split across the thread page module.
    late String threadModule;

    setUpAll(() {
      String read(String path) {
        final f = File(path);
        expect(f.existsSync(), isTrue, reason: 'missing $path');
        return f.readAsStringSync();
      }

      homePage = read('lib/ui/home/home_page.dart');
      frontLayer = read('lib/ui/home/widgets/home_page_front_layer.dart');
      startup = read('lib/ui/startup_screen.dart');
      styledHtml = read('lib/ui/common/styled_html_view.dart');
      commentCell = read('lib/ui/thread/comment_cell/comment_cell.dart');
      previousSliver =
          read('lib/ui/thread/widgets/thread_page_previous_sliver.dart');
      appBar = read('lib/ui/thread/widgets/thread_page_app_bar.dart');
      threadPageState =
          read('lib/models/ui_state_models/thread_page_state.dart');
      richTextEditor =
          read('lib/ui/common/compose_page/widgets/rich_text_editor.dart');
      richTextToolbar =
          read('lib/ui/common/compose_page/widgets/rich_text_toolbar.dart');
      composePage = read('lib/ui/common/compose_page/compose_page.dart');
      homeDrawer = read('lib/ui/home/drawer/home_drawer.dart');
      threadPageFooter =
          read('lib/ui/thread/widgets/thread_page_footer.dart');
      threadPageSliver =
          read('lib/ui/thread/widgets/thread_page_sliver.dart');
      threadPageScrollListener = read(
          'lib/ui/thread/functions/thread_page_scroll_controller_listener.dart');
      threadPage = read('lib/ui/thread/thread_page.dart');
      threadPageLoadedBody =
          read('lib/ui/thread/widgets/thread_page_loaded_body.dart');
      threadPageScrollController =
          read('lib/ui/thread/thread_page_scroll_controller.dart');
      previousPagePullController =
          read('lib/ui/thread/previous_page_pull_controller.dart');
      threadRestoreController =
          read('lib/ui/thread/thread_restore_controller.dart');
      replyPositionAnchor =
          read('lib/ui/thread/reply_position_anchor.dart');
      previousPullIndicator = read(
          'lib/ui/thread/widgets/thread_page_previous_pull_indicator.dart');
      threadModule = [
        threadPage,
        threadPageLoadedBody,
        threadPageScrollController,
        previousPagePullController,
        threadRestoreController,
        replyPositionAnchor,
        previousPullIndicator,
        threadPageScrollListener,
        threadPageSliver,
        previousSliver,
      ].join('\n');
    });

    test('H1: home Scaffold is outside ThreadListBloc builder', () {
      expect(homePage.contains('BlocBuilder<ThreadListBloc'), isFalse);
      expect(frontLayer.contains('BlocBuilder<ThreadListBloc'), isTrue);
      expect(frontLayer.contains('ThreadListAppending'), isTrue);
      expect(homePage.contains('BackdropScaffold'), isTrue);
    });

    test('H1/M5: front layer pre-filters blocked threads', () {
      expect(frontLayer.contains('visibleThreads'), isTrue);
      expect(frontLayer.contains('blockedUserIds'), isTrue);
    });

    test('M8: home list rebuilds on SessionUser block list changes', () {
      expect(frontLayer.contains('BlocBuilder<SessionUserBloc'), isTrue);
      expect(frontLayer.contains('_sameBlockedUsers'), isTrue);
    });

    test('drawer listens to ChannelBloc independently', () {
      expect(homeDrawer.contains('BlocBuilder<ChannelBloc'), isTrue);
    });

    test('H4: startup kickoff is not in build()', () {
      expect(startup.contains('_bootstrapOnce'), isTrue);
      expect(startup.contains('_kickoffStarted'), isTrue);
      final buildIdx = startup.indexOf('Widget build(BuildContext context)');
      expect(buildIdx, greaterThan(0));
      final buildBody = startup.substring(buildIdx);
      expect(buildBody.contains('_controller.forward()'), isFalse);
      expect(buildBody.contains('RequestThreadListEvent'), isFalse);
    });

    test('H3/M4: StyledHtmlView keeps Hero + short OctoImage fade', () {
      expect(styledHtml.contains('StyledHtmlViewCubit'), isFalse);
      expect(styledHtml.contains('_HtmlNetworkImage'), isTrue);
      expect(styledHtml.contains(r'${widget.floor}_${src}_$_randomHash'), isTrue);
      expect(styledHtml.contains(r'$state.randomHash'), isFalse);
      expect(styledHtml.contains('RepaintBoundary'), isTrue);
      expect(styledHtml.contains('Hero('), isTrue);
      expect(styledHtml.contains('placeholderBuilder: _heroPlaceholder'), isTrue);
      expect(styledHtml.contains('OctoImage('), isTrue);
      expect(styledHtml.contains('gaplessPlayback: true'), isTrue);
      expect(styledHtml.contains('_kImageFadeIn'), isTrue);
      expect(styledHtml.contains('_kImageFadeOut'), isTrue);
      expect(styledHtml.contains('milliseconds: 150'), isTrue);
      expect(styledHtml.contains('data-sx'), isTrue);
      expect(styledHtml.contains('data-sy'), isTrue);
    });

    test('P0: image aspect cache reserves height before decode', () {
      final aspectStore =
          File('lib/utils/image_aspect_ratio_store.dart').readAsStringSync();
      final mainDart = File('lib/main.dart').readAsStringSync();
      expect(aspectStore.contains('class ImageAspectRatioStore'), isTrue);
      expect(aspectStore.contains("boxName = 'image_aspect_ratios'"), isTrue);
      expect(aspectStore.contains('fallbackAspectRatio'), isTrue);
      expect(aspectStore.contains('maxEntries = 500'), isTrue);
      expect(aspectStore.contains('naturalWidth'), isTrue);
      expect(mainDart.contains('ImageAspectRatioStore.boxName'), isTrue);
      expect(styledHtml.contains('ImageAspectRatioStore'), isTrue);
      expect(styledHtml.contains('fallbackAspectRatio'), isTrue);
      expect(styledHtml.contains('_layoutSize'), isTrue);
      expect(styledHtml.contains('_naturalWidthLogical'), isTrue);
      // Do not upscale past natural pixel width (data-sx / cache).
      expect(styledHtml.contains('min(maxWidth, natural)'), isTrue);
      // Decode stream provides true aspect — not the reserved layout box.
      expect(styledHtml.contains('_listenForDecodedSize'), isTrue);
      expect(styledHtml.contains('_decodedAspectRatio'), isTrue);
      // Error tile stays a fixed reserved box, not a bare shrinking row.
      expect(styledHtml.contains('ImageLoadingError'), isTrue);
      expect(styledHtml.contains('displayHeight'), isTrue);
    });

    test('R1: StyledHtmlView memoizes Html across rebuilds', () {
      expect(styledHtml.contains('_cachedHtml'), isTrue);
      expect(styledHtml.contains('didUpdateWidget'), isTrue);
      expect(styledHtml.contains('Object.hash'), isTrue);
      expect(styledHtml.contains('_cachedCacheWidth'), isTrue);
      expect(styledHtml.contains('_cachedThemeKey'), isTrue);
      expect(styledHtml.contains('RepaintBoundary'), isTrue);
      expect(styledHtml.contains('_HtmlNetworkImage'), isTrue);
      // SelectionArea wraps outside the cached Html so selection UI is not memoized.
      expect(styledHtml.contains('SelectionArea('), isTrue);
      final selectionIdx = styledHtml.indexOf('SelectionArea(');
      final repaintIdx = styledHtml.indexOf('RepaintBoundary(', selectionIdx);
      final cachedIdx = styledHtml.indexOf('_cachedHtml!', repaintIdx);
      expect(repaintIdx, greaterThan(selectionIdx));
      expect(cachedIdx, greaterThan(repaintIdx));
      // Copy clears selection; Select All keeps it (default button item).
      expect(styledHtml.contains('contextMenuBuilder:'), isTrue);
      expect(styledHtml.contains('ContextMenuButtonType.copy'), isTrue);
      expect(styledHtml.contains('clearSelection()'), isTrue);
    });

    test('R2: CommentCell keeps alive; keeps RepaintBoundary', () {
      // Keep-alive avoids wrong reuse / out-of-order replies after LRU budgeting.
      expect(commentCell.contains('AutomaticKeepAliveClientMixin'), isTrue);
      expect(commentCell.contains('wantKeepAlive => true'), isTrue);
      expect(commentCell.contains('RepaintBoundary'), isTrue);
    });

    test('R3: toolbar setState only when selection flags change', () {
      expect(richTextToolbar.contains('_onSelectionChanged'), isTrue);
      expect(richTextToolbar.contains('isBold == _isBold'), isTrue);
      expect(richTextToolbar.contains('parsedColor == _activeColor'), isTrue);
      expect(richTextToolbar.contains('return;'), isTrue);
    });

    test('R4: list Theme is hoisted to home_page, not front layer', () {
      expect(homePage.contains('highlightColor: const Color(0xff373d3c)'),
          isTrue);
      expect(homePage.contains('frontLayer: Theme('), isTrue);
      expect(frontLayer.contains('highlightColor'), isFalse);
      expect(frontLayer.contains('return Theme('), isFalse);
      expect(frontLayer.contains('return Material('), isTrue);
    });

    test('R5: footer reads onLastPage from ThreadPageCubit', () {
      expect(threadPageFooter.contains('onLastPage'), isTrue);
      expect(
          threadPageFooter.contains(
              'BlocBuilder<ThreadPageCubit, ThreadPageState>'),
          isTrue);
      expect(
          threadPageFooter
              .contains('prev.onLastPage != next.onLastPage'),
          isTrue);
      expect(threadPageFooter.contains('BlocBuilder<ThreadBloc'), isTrue);
      // Footer does not wrap SafeArea; list is edge-to-edge.
      expect(threadPageFooter.contains('SafeArea('), isFalse);
      expect(threadPageSliver.contains('_PageFooter('), isTrue);
      expect(threadPageSliver.contains('onLastPage:'), isFalse);
    });

    test('R6: load-more footer only when ThreadListAppending', () {
      // Outer list skips rebuilds while appending; footer listens independently.
      expect(frontLayer.contains('if (state is ThreadListAppending)'), isTrue);
      expect(frontLayer.contains('return false;'), isTrue);
      expect(
          frontLayer.contains(
              '(prev is ThreadListAppending) != (next is ThreadListAppending)'),
          isTrue);
      expect(frontLayer.contains('if (listState is ThreadListAppending)'),
          isTrue);
      expect(frontLayer.contains('_ThreadListLoadMoreFooter'), isTrue);
      expect(frontLayer.contains('CircularProgressIndicator'), isTrue);
      expect(frontLayer.contains('SizedBox.shrink()'), isTrue);
      expect(frontLayer.contains('ListLoadingSkeletonCell'), isFalse);
    });

    test('M8: CommentCell reactively filters blocked authors', () {
      expect(commentCell.contains('BlocBuilder<SessionUserBloc'), isTrue);
      expect(commentCell.contains('_isAuthorBlocked'), isTrue);
    });

    test('canReply is live from ThreadPageCubit, not constructor snapshot', () {
      expect(commentCell.contains('BlocBuilder<ThreadPageCubit'), isTrue);
      expect(commentCell.contains('required this.canReply'), isFalse);
      expect(composePage.contains('buildWhen'), isTrue);
      final threadPage =
          File('lib/ui/thread/thread_page.dart').readAsStringSync();
      final scaffoldCount = 'Scaffold('.allMatches(threadPage).length;
      expect(scaffoldCount, 1);
    });

    test('M1: previous sliver keys with ValueKey for findChildIndexCallback',
        () {
      expect(previousSliver.contains('ValueKey<Object>(_replyListKey(reply))'),
          isTrue);
      expect(previousSliver.contains('KeyedSubtree'), isTrue);
      final threadPage = File('lib/ui/thread/thread_page.dart').readAsStringSync();
      expect(threadPage.contains('previousKeyToBuilderIndex'), isTrue);
      expect(
          threadPage.contains(
              'state.previousPages.replies.length - i - 1'),
          isTrue);
      expect(threadPage.contains('BlocListener<SessionUserBloc'), isTrue);
    });

    test('M2: app bar rebuilds only on elevation change', () {
      expect(appBar.contains('buildWhen'), isTrue);
      expect(appBar.contains('prev.elevation != next.elevation'), isTrue);
    });

    test('M7: canReply included in ThreadPageState.props', () {
      expect(threadPageState.contains('canReply'), isTrue);
      expect(
          threadPageState
              .contains('props => [onLastPage, canReply, elevation]'),
          isTrue);
    });

    test('M3: rich text editor owns ScrollController; compose has no title setState',
        () {
      expect(richTextEditor.contains('class _RichTextEditor extends StatefulWidget'),
          isTrue);
      expect(richTextEditor.contains('ScrollController()'), isTrue);
      expect(richTextEditor.contains('_scrollController'), isTrue);
      expect(composePage.contains('_titleFieldController.text'), isTrue);
      expect(composePage.contains("setState(() {\n                              _title"),
          isFalse);
      expect(composePage.contains('_cachedQuoteHtml'), isTrue);
    });

    test('previous page uses RefreshIndicator-style pull, not in-list skeleton',
        () {
      expect(previousPagePullController.contains('armExtent'), isTrue);
      expect(threadPageScrollListener.contains('endPage + 1'), isTrue);
      expect(threadPageScrollListener.contains('currentPage - 1'), isFalse);
      expect(threadPage.contains('_onThreadScrollNotification'), isTrue);
      expect(previousPagePullController.contains('armed'), isTrue);
      expect(
          previousPagePullController.contains('HapticFeedback.mediumImpact'),
          isTrue);
      expect(threadPageLoadedBody.contains('ThreadScrollPhysics'), isTrue);
      expect(threadPageLoadedBody.contains('clampLeading'), isTrue);
      expect(threadPageLoadedBody.contains('currentPage > 1'), isTrue);
      expect(
          threadPageLoadedBody.contains('threadScrollBounceEnabled'), isTrue);
      expect(threadPageLoadedBody.contains('Transform.translate'), isTrue);
      expect(previousPagePullController.contains('animateExtentTo'), isTrue);
      expect(threadModule.contains('_PreviousPullIndicator'), isTrue);
      expect(
          previousPagePullController.contains('OverscrollNotification'),
          isTrue);
      expect(previousPagePullController.contains('extentBefore'), isTrue);
      expect(
          previousPagePullController.contains('ScrollEndNotification'),
          isTrue);
      expect(threadModule.contains('ScrollDirection.idle'), isFalse);
      expect(
          threadPageLoadedBody
              .contains('NotificationListener<ScrollNotification>'),
          isTrue);
      expect(previousSliver.contains('ThreadPageLoadingSkeletonCell'), isFalse);
      expect(
          previousPullIndicator.contains('ThreadPageLoadingSkeletonCell'),
          isTrue);
      expect(
          previousPullIndicator.contains('scaffoldBackgroundColor'), isTrue);
      final scrollPhysics =
          File('lib/ui/thread/thread_scroll_physics.dart').readAsStringSync();
      expect(scrollPhysics.contains('class ThreadScrollPhysics'), isTrue);
    });

    test('thread page pins center and does not restore scroll offset', () {
      expect(threadPage.contains('keepScrollOffset: false'), isTrue);
      expect(
          threadPageScrollController.contains('class ThreadPageScrollController'),
          isTrue);
      expect(threadPageScrollController.contains('holdCenterAtZero'), isTrue);
      expect(threadPageScrollController.contains('minScrollExtent'), isTrue);
      expect(threadRestoreController.contains('didPinInitialCenter'), isTrue);
      expect(threadRestoreController.contains('jumpTo(0)'), isTrue);
      expect(threadPageScrollController.contains('void jumpTo(double value)'),
          isTrue);
      // Last-reply restore: trailing edge + top pad for short pages.
      expect(
          threadRestoreController.contains('pendingRestoreToTrailingEdge'),
          isTrue);
      expect(
          threadRestoreController.contains('trailingEdgeLayoutActive'),
          isTrue);
      expect(threadRestoreController.contains('trailingTopPad'), isTrue);
      expect(threadPage.contains('_syncTrailingEdgeLayout'), isTrue);
      expect(threadPage.contains('_footerMeasureKey'), isTrue);
      expect(threadRestoreController.contains('maxScrollExtent'), isTrue);
      // Hide pre-pin frames; reveal after pad/offset stabilize.
      expect(threadRestoreController.contains('visualReady'), isTrue);
      expect(threadRestoreController.contains('revealContent'), isTrue);
      expect(threadRestoreController.contains('notePinApplied'), isTrue);
      expect(threadRestoreController.contains('revealTimeout'), isTrue);
      // Edge-to-edge viewport; safe area applied as scroll content insets.
      expect(threadModule.contains('SafeArea('), isFalse);
      expect(threadPageLoadedBody.contains('viewPadding'), isTrue);
      expect(threadPageLoadedBody.contains('SliverPadding'), isTrue);
      // Restore settle loop re-pins while remote images/embeds change extent.
      expect(threadRestoreController.contains('settling'), isTrue);
      expect(threadPage.contains('_startRestoreSettle'), isTrue);
      expect(threadRestoreController.contains('cancelSettle'), isTrue);
      expect(threadRestoreController.contains('applyPin'), isTrue);
      expect(threadRestoreController.contains('settleDuration'), isTrue);
      // Module split: orchestration stays thin; helpers are libraries.
      expect(threadPage.contains('PreviousPagePullController'), isTrue);
      expect(threadPage.contains('ThreadRestoreController'), isTrue);
      expect(threadPage.contains('ReplyAnchorRegistry'), isTrue);
      expect(threadPage.contains('_buildLoadedThreadBody'), isTrue);
      final loadingSkeleton = File(
              'lib/ui/thread/skeletons/thread_page_loading_skeleton.dart')
          .readAsStringSync();
      expect(loadingSkeleton.contains('primary: false'), isTrue);
    });
  });
}

