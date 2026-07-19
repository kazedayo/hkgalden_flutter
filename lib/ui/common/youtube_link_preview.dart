import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:hkgalden_flutter/utils/youtube_oembed_cache.dart';
import 'package:hkgalden_flutter/utils/youtube_url.dart';
import 'package:octo_image/octo_image.dart';

/// Compact preview under a YouTube link (link text stays above).
class YoutubeLinkPreview extends StatefulWidget {
  final String href;
  final String videoId;
  final VoidCallback onOpen;
  final YoutubeOEmbedCache? cache;

  const YoutubeLinkPreview({
    super.key,
    required this.href,
    required this.videoId,
    required this.onOpen,
    this.cache,
  });

  @override
  State<YoutubeLinkPreview> createState() => _YoutubeLinkPreviewState();
}

class _YoutubeLinkPreviewState extends State<YoutubeLinkPreview> {
  late Future<YoutubeOEmbedInfo?> _future;

  YoutubeOEmbedCache get _cache =>
      widget.cache ?? YoutubeOEmbedCache.instance;

  @override
  void initState() {
    super.initState();
    _future = _cache.fetch(widget.videoId);
  }

  @override
  void didUpdateWidget(covariant YoutubeLinkPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _future = _cache.fetch(widget.videoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = YoutubeUrl.thumbnailUrl(widget.videoId);

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
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: thumbWidth,
                        height: thumbHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            OctoImage(
                              image: NetworkImage(thumb),
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 150),
                              fadeOutDuration:
                                  const Duration(milliseconds: 100),
                              placeholderBuilder: (_) => ColoredBox(
                                color: theme.dividerColor,
                              ),
                              errorBuilder: (context, error, stackTrace) =>
                                  ColoredBox(
                                color: theme.dividerColor,
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white70,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          child: FutureBuilder<YoutubeOEmbedInfo?>(
                            future: _future,
                            builder: (context, snapshot) {
                              final info = snapshot.data;
                              final title = info?.title ??
                                  (snapshot.connectionState ==
                                          ConnectionState.waiting
                                      ? 'Loading…'
                                      : 'YouTube video');
                              final subtitle = info?.authorName ?? 'youtube.com';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
