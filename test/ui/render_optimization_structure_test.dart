import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/utils/html_styles.dart';

/// Structural + unit checks for render-optimization changes.
/// Drives real shipped [HtmlStyles.generate] and asserts source patterns
/// that implement rebuild-scope narrowing.
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
    late String composePage;
    late String homeDrawer;

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
      composePage = read('lib/ui/common/compose_page/compose_page.dart');
      homeDrawer = read('lib/ui/home/drawer/home_drawer.dart');
    });

    test('H1: home Scaffold is outside ThreadListBloc builder', () {
      // BlocBuilder should live in front layer, not wrap BackdropScaffold.
      expect(homePage.contains('BlocBuilder<ThreadListBloc'), isFalse);
      expect(frontLayer.contains('BlocBuilder<ThreadListBloc'), isTrue);
      expect(frontLayer.contains('ThreadListAppending'), isTrue);
      expect(homePage.contains('BackdropScaffold'), isTrue);
    });

    test('H1/M5: front layer pre-filters blocked threads', () {
      expect(frontLayer.contains('visibleThreads'), isTrue);
      expect(frontLayer.contains('SizedBox.shrink()'), isFalse);
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
      // build must not call forward().whenComplete for network kickoff
      final buildIdx = startup.indexOf('Widget build(BuildContext context)');
      expect(buildIdx, greaterThan(0));
      final buildBody = startup.substring(buildIdx);
      expect(buildBody.contains('_controller.forward()'), isFalse);
      expect(buildBody.contains('RequestThreadListEvent'), isFalse);
    });

    test('H3/M4: StyledHtmlView uses local image state and fixed hero tag', () {
      expect(styledHtml.contains('StyledHtmlViewCubit'), isFalse);
      expect(styledHtml.contains('_HtmlNetworkImage'), isTrue);
      expect(styledHtml.contains(r'${widget.floor}_${src}_$_randomHash'), isTrue);
      // Broken Dart interpolation must not remain.
      expect(styledHtml.contains(r'$state.randomHash'), isFalse);
      expect(styledHtml.contains('RepaintBoundary'), isTrue);
    });

    test('H2: CommentCell uses keep-alive and RepaintBoundary', () {
      expect(commentCell.contains('AutomaticKeepAliveClientMixin'), isTrue);
      expect(commentCell.contains('RepaintBoundary'), isTrue);
      expect(commentCell.contains('wantKeepAlive'), isTrue);
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
      // Nested outer Scaffold removed.
      final scaffoldCount = 'Scaffold('.allMatches(threadPage).length;
      expect(scaffoldCount, 1);
    });

    test('M1: previous sliver keys with ValueKey for findChildIndexCallback',
        () {
      expect(previousSliver.contains('ValueKey(reply.replyId)'), isTrue);
      expect(previousSliver.contains('KeyedSubtree'), isTrue);
      final threadPage = File('lib/ui/thread/thread_page.dart').readAsStringSync();
      // Builder is reversed; callback must convert data index → builder index.
      expect(
          threadPage.contains(
              'state.previousPages.replies.length -\n                                dataIndex -\n                                1') ||
              threadPage.contains(
                  'state.previousPages.replies.length - dataIndex - 1') ||
              threadPage.contains('dataIndex -'),
          isTrue);
      expect(threadPage.contains('dataIndex < 0'), isTrue);
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
      // Not created inline in build as `ScrollController()` on QuillEditor line
      // without a field — field assignment pattern:
      expect(richTextEditor.contains('_scrollController'), isTrue);
      expect(composePage.contains('_titleFieldController.text'), isTrue);
      expect(composePage.contains("setState(() {\n                              _title"),
          isFalse);
      expect(composePage.contains('_cachedQuoteHtml'), isTrue);
    });
  });
}
