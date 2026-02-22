part of '../home_page.dart';

void _jumpToPage(BuildContext context, Thread thread) {
  HapticFeedback.mediumImpact();
  showMaterialModalBottomSheet(
    useRootNavigator: true,
    duration: const Duration(milliseconds: 200),
    animationCurve: Curves.easeOut,
    enableDrag: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    context: context,
    builder: (context) => Theme(
      data: Theme.of(context).copyWith(highlightColor: Colors.grey[800]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              thread.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height / 2),
            child: ListView.builder(
              shrinkWrap: true,
              padding:
                  EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
              itemCount: (thread.replies.last.floor.toDouble() / 50.0).ceil(),
              itemBuilder: (context, index) => Card(
                color: Colors.transparent,
                elevation: 0,
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SimpleDialogOption(
                  padding: const EdgeInsets.all(16.0),
                  onPressed: () {
                    Navigator.of(context).pop();
                    navigatorKey.currentState!.pushNamed(
                      '/Thread',
                      arguments: ThreadPageArguments(
                          threadId: thread.threadId,
                          title: thread.title,
                          page: index + 1,
                          locked: thread.status == 'locked'),
                    );
                  },
                  child: Text(
                    '第 ${index + 1} 頁',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    ),
  );
}
