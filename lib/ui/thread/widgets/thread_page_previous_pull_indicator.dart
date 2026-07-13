part of '../thread_page.dart';

/// Skeleton revealed in the gap above translated content during previous pull.
///
/// Uses an opaque scaffold fill so thread posts never show through the shimmer.
/// The skeleton always lays out at full height inside an [OverflowBox]; only the
/// outer [Positioned] height grows with the pull — avoids RenderFlex overflow
/// when the gap is only a few pixels tall.
class _PreviousPullIndicator extends StatelessWidget {
  const _PreviousPullIndicator({
    required this.extent,
    required this.loading,
  });

  final double extent;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final height = loading
        ? _kPreviousPullIndicatorMaxExtent
        : extent.clamp(0.0, _kPreviousPullIndicatorMaxExtent);
    if (height <= 0) {
      return const SizedBox.shrink();
    }

    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: ColoredBox(
          color: bg,
          // LayoutBuilder gives a finite width from the Positioned constraints.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return ClipRect(
                child: OverflowBox(
                  // Reveal from the content edge (bottom of the gap) as pull grows.
                  alignment: Alignment.bottomCenter,
                  minWidth: width,
                  maxWidth: width,
                  minHeight: ThreadPageLoadingSkeletonCell.totalHeight,
                  maxHeight: ThreadPageLoadingSkeletonCell.totalHeight,
                  child: SizedBox(
                    width: width,
                    height: ThreadPageLoadingSkeletonCell.totalHeight,
                    child: ColoredBox(
                      color: bg,
                      child: const ThreadPageLoadingSkeletonCell(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
