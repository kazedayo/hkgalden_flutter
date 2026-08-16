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
    late String appBar;
    late String threadPageState;
    late String richTextEditor;
    late String richTextToolbar;
    late String composePage;
    late String homeDrawer;
    late String threadPage;
    late String previousPagePullController;
    late String threadPageBlocListener;
    late String threadWebView;
    late String threadWebViewJs;
    late String threadWebViewMessages;
    late String threadWebViewHtml;
    late String threadWebViewCss;
    late String threadWebViewRenderJs;
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
      appBar = read('lib/ui/thread/widgets/thread_page_app_bar.dart');
      threadPageState =
          read('lib/models/ui_state_models/thread_page_state.dart');
      richTextEditor =
          read('lib/ui/common/compose_page/widgets/rich_text_editor.dart');
      richTextToolbar =
          read('lib/ui/common/compose_page/widgets/rich_text_toolbar.dart');
      composePage = read('lib/ui/common/compose_page/compose_page.dart');
      homeDrawer = read('lib/ui/home/drawer/home_drawer.dart');
      threadPage = read('lib/ui/thread/thread_page.dart');
      previousPagePullController =
          read('lib/ui/thread/previous_page_pull_controller.dart');
      threadPageBlocListener =
          read('lib/ui/thread/thread_page_bloc_listener.dart');
      threadWebView = read('lib/ui/thread/webview/thread_webview.dart');
      threadWebViewJs = read('lib/ui/thread/webview/thread_webview_js.dart');
      threadWebViewMessages =
          read('lib/ui/thread/webview/thread_webview_messages.dart');
      threadWebViewHtml = read('assets/thread_webview/index.html');
      threadWebViewCss = read('assets/thread_webview/thread.css');
      threadWebViewRenderJs = read('assets/thread_webview/render.js');
      threadModule = [
        threadPage,
        previousPagePullController,
        threadPageBlocListener,
        threadWebView,
        threadWebViewJs,
        threadWebViewMessages,
        appBar,
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

    test('R2: thread page uses a single WebView keyed by thread id', () {
      expect(threadPage.contains('ThreadWebView('), isTrue);
      expect(threadPage.contains('ValueKey<int>(arguments.threadId)'), isTrue);
      expect(threadPage.contains('StyledHtmlView('), isFalse);
      expect(threadWebView.contains('loadHtmlString'), isTrue);
      expect(threadWebView.contains('loadThreadWebViewShell'), isTrue);
      expect(threadWebView.contains('loadFlutterAsset'), isFalse);
      expect(threadWebView.contains("addJavaScriptChannel(\n        'Galden'"),
          isTrue);
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

    test('R5: footer flags come from ThreadPageCubit via JS setFlags', () {
      expect(threadWebView.contains('onLastPage'), isTrue);
      expect(threadWebView.contains("send('setFlags'"), isTrue);
      expect(threadWebView.contains('pageState.onLastPage'), isTrue);
      expect(threadModule.contains('SafeArea('), isFalse);
    });

    test('R5b: footer spinner follows Theme.platform', () {
      expect(threadWebView.contains("'platform'"), isTrue);
      expect(threadWebView.contains('TargetPlatform.iOS'), isTrue);
      expect(threadWebViewRenderJs.contains('spinner-ios'), isTrue);
      expect(threadWebViewRenderJs.contains('spinner-android'), isTrue);
      expect(threadWebViewCss.contains('spinner-ios'), isTrue);
      expect(threadWebViewCss.contains('steps(8)'), isTrue);
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

    test('M8: WebView applies blocked authors without rebuilding the shell', () {
      expect(threadWebView.contains('setBlockedUsers'), isTrue);
      expect(threadWebView.contains('BlocListener<SessionUserBloc'), isTrue);
    });

    test('canReply is live from ThreadPageCubit, not constructor snapshot', () {
      expect(threadWebView.contains('pageState.canReply'), isTrue);
      expect(composePage.contains('buildWhen'), isTrue);
      final scaffoldCount = 'Scaffold('.allMatches(threadPage).length;
      expect(scaffoldCount, 1);
    });

    test('M1: previous replies are prepended incrementally', () {
      expect(threadWebView.contains("send('prependReplies'"), isTrue);
      expect(threadWebView.contains("send('appendReplies'"), isTrue);
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

    test('previous page pull lives in the WebView, not a Flutter overlay', () {
      expect(previousPagePullController.contains('handleJsPull'), isTrue);
      expect(
          previousPagePullController.contains('HapticFeedback.mediumImpact'),
          isTrue);
      expect(threadPage.contains('Transform.translate'), isFalse);
      expect(threadPage.contains('ThreadPagePreviousPullIndicator'), isFalse);
      expect(threadWebView.contains('setOverScrollMode'), isFalse);
      expect(threadWebView.contains('canPullPrevious'), isTrue);
      expect(threadWebView.contains('resetPull'), isTrue);
      expect(threadWebViewHtml.contains('id="previous-pull"'), isTrue);
      expect(threadWebViewCss.contains('#previous-pull'), isTrue);
      expect(threadWebViewCss.contains('html.pulling-previous'), isTrue);
      expect(threadWebViewRenderJs.contains("phase: 'load'"), isTrue);
      expect(threadWebViewRenderJs.contains('preventDefault'), isTrue);
      expect(threadWebViewRenderJs.contains('translateY'), isTrue);
      expect(threadWebView.contains('endPage + 1'), isTrue);
      expect(threadWebView.contains('currentPage - 1'), isFalse);
    });

    test('thread page restores via scrollToFloor, not sliver center pin', () {
      expect(threadPage.contains('restoreFloor'), isTrue);
      expect(threadWebView.contains('scrollToFloor'), isTrue);
      expect(threadPage.contains('ThreadRestoreController'), isFalse);
      expect(threadPage.contains('ReplyAnchorRegistry'), isFalse);
      expect(threadPage.contains('buildLoadedThreadBody'), isFalse);
      expect(threadPage.contains('part '), isFalse);
      expect(threadPage.contains('didChangeDependencies'), isTrue);
      expect(threadPage.contains('remeasure: false'), isTrue);
      expect(threadPage.contains('PreviousPagePullController'), isTrue);
      expect(threadPage.contains('handleThreadPageBlocState'), isTrue);
      expect(threadPageBlocListener.contains('handleThreadPageBlocState'),
          isTrue);
      final loadingSkeleton = File(
              'lib/ui/thread/skeletons/thread_page_loading_skeleton.dart')
          .readAsStringSync();
      expect(loadingSkeleton.contains('primary: false'), isTrue);
    });

    test('reading floor persists from settled JS scroll, not every tick', () {
      expect(threadPage.contains('onScrollTick'), isFalse);
      expect(threadPage.contains('_updateCachedReadingFloor'), isFalse);
      expect(threadWebView.contains("flag('settled')"), isTrue);
      expect(threadWebView.contains('void persist('), isTrue);
      expect(threadWebView.contains('ThreadReadingPositionStore'), isTrue);
      expect(previousPagePullController.contains('onScrollTick'), isFalse);
    });
  });
}

