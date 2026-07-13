part of '../thread_page.dart';

/// Pull-gap skeleton; [OverflowBox] keeps full layout while outer height grows.
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return ClipRect(
                child: OverflowBox(
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
