import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:hkgalden_flutter/utils/x_status_cache.dart';

/// Compact preview under an X (Twitter) status link (link text stays above).
class XLinkPreview extends StatefulWidget {
  final String href;
  final String statusId;
  final VoidCallback onOpen;
  final XStatusCache? cache;

  const XLinkPreview({
    super.key,
    required this.href,
    required this.statusId,
    required this.onOpen,
    this.cache,
  });

  @override
  State<XLinkPreview> createState() => _XLinkPreviewState();
}

class _XLinkPreviewState extends State<XLinkPreview> {
  late Future<XStatusInfo?> _future;

  XStatusCache get _cache => widget.cache ?? XStatusCache.instance;

  @override
  void initState() {
    super.initState();
    _future = _cache.fetch(widget.statusId);
  }

  @override
  void didUpdateWidget(covariant XLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusId != widget.statusId) {
      _future = _cache.fetch(widget.statusId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final thumbWidth = (maxWidth * 0.38).clamp(96.0, 140.0);
        final thumbHeight = thumbWidth * 9 / 16;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Material(
            color: AppTheme.linkPreviewBackground(theme.colorScheme),
            shape: const RoundedRectangleBorder(
              borderRadius: AppTheme.linkPreviewRadius,
              side: AppTheme.linkPreviewBorder,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onOpen,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: FutureBuilder<XStatusInfo?>(
                  future: _future,
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final waiting =
                        snapshot.connectionState == ConnectionState.waiting;
                    final author = info?.authorName ??
                        (waiting ? 'Loading…' : 'Post on X');
                    final body = info?.text;
                    final hasBody =
                        body != null && body.trim().isNotEmpty;
                    final imageUrl = info?.imageUrl;
                    final hasImage =
                        imageUrl != null && imageUrl.isNotEmpty;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (hasImage)
                            SizedBox(
                              width: thumbWidth,
                              height: thumbHeight,
                              child: Image(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loading) =>
                                    loading == null
                                        ? child
                                        : ColoredBox(color: theme.dividerColor),
                                errorBuilder: (context, error, stackTrace) =>
                                    ColoredBox(
                                  color: theme.dividerColor,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(
                              width: 4,
                              child: ColoredBox(
                                color: AppTheme.quoteLineColor,
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '𝕏',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme
                                              .textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasBody) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      body,
                                      maxLines: hasImage ? 2 : 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(height: 1.3),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    info?.authorScreenName != null
                                        ? '@${info!.authorScreenName}'
                                        : 'x.com',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
