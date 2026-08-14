import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/thread/reply_position_anchor.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_reading_position_tracker.dart';
import 'package:hkgalden_flutter/ui/thread/thread_restore_controller.dart';

void main() {
  group('trailing-edge restore during layout', () {
    testWidgets(
      'viewportTopY returns null while an ancestor is laying out',
      (tester) async {
        final scrollController = ThreadPageScrollController();
        final tracker = ThreadReadingPositionTracker(
          scrollController: scrollController,
          anchorRegistry: ReplyAnchorRegistry(),
        );
        addTearDown(scrollController.dispose);

        double? duringLayout;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Transform.translate(
                offset: Offset.zero,
                child: _LayoutProbe(
                  onPerformLayout: () {
                    duringLayout = tracker.viewportTopY();
                  },
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: const [
                      SliverToBoxAdapter(child: SizedBox(height: 400)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(duringLayout, isNull);
        expect(tracker.viewportTopY(), isNotNull);
      },
    );

    testWidgets(
      'syncTrailingEdgeLayout does not throw when media grows during layout',
      (tester) async {
        final env = _RestoreEnv();
        addTearDown(env.dispose);

        await tester.pumpWidget(
          _RestoreScrollHarness(
            env: env,
            childHeight: 400,
          ),
        );

        await tester.pumpWidget(
          _RestoreScrollHarness(
            env: env,
            childHeight: 2400,
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(env.scrollController.hasClients, isTrue);
        expect(
          env.scrollController.position.pixels,
          closeTo(env.scrollController.position.maxScrollExtent, 1.5),
        );
      },
    );

    test('revealContent stops pinning so later media loads cannot jump', () {
      final restore = ThreadRestoreController();
      restore.visualReady.value = false;
      restore.settling = true;
      restore.trailingEdgeLayoutActive = true;

      restore.revealContent();

      expect(restore.visualReady.value, isTrue);
      expect(restore.settling, isFalse);
      expect(restore.trailingEdgeLayoutActive, isFalse);
    });

    testWidgets(
      'jumpTo from trailing sync does not recurse through ScrollEnd',
      (tester) async {
        final env = _RestoreEnv();
        addTearDown(env.dispose);

        await tester.pumpWidget(
          _RestoreScrollHarness(
            env: env,
            childHeight: 2400,
          ),
        );

        env.scrollController.jumpTo(0);
        await tester.pump();

        env.restore.syncTrailingEdgeLayout(
          mounted: true,
          scrollController: env.scrollController,
          footerBottomY: () => 800,
          viewportTopY: env.tracker.viewportTopY,
          safeBottom: 0,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          env.scrollController.position.pixels,
          closeTo(env.scrollController.position.maxScrollExtent, 1.5),
        );
      },
    );
  });
}

class _RestoreEnv {
  _RestoreEnv() {
    restore.pendingRestoreToTrailingEdge = true;
    restore.trailingEdgeLayoutActive = true;
    restore.visualReady.value = false;
  }

  final scrollController = ThreadPageScrollController();
  final restore = ThreadRestoreController();
  late final tracker = ThreadReadingPositionTracker(
    scrollController: scrollController,
    anchorRegistry: ReplyAnchorRegistry(),
  );

  void sync() {
    restore.syncTrailingEdgeLayout(
      mounted: true,
      scrollController: scrollController,
      footerBottomY: () => 800,
      viewportTopY: tracker.viewportTopY,
      safeBottom: 0,
    );
  }

  void dispose() {
    restore.dispose();
    scrollController.dispose();
  }
}

/// Mirrors production: Transform.translate + metrics/end sync during restore.
class _RestoreScrollHarness extends StatelessWidget {
  const _RestoreScrollHarness({
    required this.env,
    required this.childHeight,
  });

  final _RestoreEnv env;
  final double childHeight;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            env.sync();
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollEndNotification) {
                env.sync();
              }
              return false;
            },
            child: Transform.translate(
              offset: Offset.zero,
              child: CustomScrollView(
                controller: env.scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: childHeight),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Invokes [onPerformLayout] from [RenderObject.performLayout].
class _LayoutProbe extends SingleChildRenderObjectWidget {
  const _LayoutProbe({
    required this.onPerformLayout,
    required super.child,
  });

  final VoidCallback onPerformLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLayoutProbe(onPerformLayout);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderLayoutProbe renderObject,
  ) {
    renderObject.onPerformLayout = onPerformLayout;
  }
}

class _RenderLayoutProbe extends RenderProxyBox {
  _RenderLayoutProbe(this.onPerformLayout);

  VoidCallback onPerformLayout;

  @override
  void performLayout() {
    super.performLayout();
    onPerformLayout();
  }
}
