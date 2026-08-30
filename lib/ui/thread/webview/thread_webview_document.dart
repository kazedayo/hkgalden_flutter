import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/utils/x_url.dart';
import 'package:hkgalden_flutter/utils/youtube_url.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

final RegExp _hexColor = RegExp(r'^#?[0-9a-fA-F]{3,8}$');

String _formatReplyDate(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.day}/${local.month}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

class RewrittenContentHtml {
  final String html;
  final List<String> youtubeIds;
  final List<String> xIds;

  const RewrittenContentHtml({
    required this.html,
    this.youtubeIds = const [],
    this.xIds = const [],
  });
}

class ThreadWebViewReplyDto {
  final String? replyId;
  final int floor;
  final String html;
  final String dateText;
  final bool isPageStart;
  final String authorUserId;
  final String nickname;
  final String avatar;
  final String? gender;
  final String? groupId;
  final List<String> youtubeIds;
  final List<String> xIds;

  const ThreadWebViewReplyDto({
    required this.replyId,
    required this.floor,
    required this.html,
    required this.dateText,
    required this.isPageStart,
    required this.authorUserId,
    required this.nickname,
    required this.avatar,
    required this.gender,
    required this.groupId,
    this.youtubeIds = const [],
    this.xIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'replyId': replyId,
        'floor': floor,
        'html': html,
        'dateText': dateText,
        'isPageStart': isPageStart,
        'author': {
          'userId': authorUserId,
          'nickname': nickname,
          'avatar': avatar,
          'gender': gender,
          'groupId': groupId,
        },
      };
}

const String kQuotePreviewImagePlaceholder = '[圖片]';

class ThreadWebViewDocument {
  const ThreadWebViewDocument({this.aspectRatioFor});

  final double? Function(String url)? aspectRatioFor;

  List<ThreadWebViewReplyDto> serializeReplies(
    Iterable<Reply> replies,
    SessionUserState sessionState,
  ) {
    return [
      for (final reply in replies) serializeReply(reply, sessionState),
    ];
  }

  ThreadWebViewReplyDto serializeReply(
    Reply reply,
    SessionUserState sessionState,
  ) {
    final raw = HKGaldenHtmlParser().commentWithQuotes(reply, sessionState) ?? '';
    final rewritten = rewriteContentHtml(raw);
    return ThreadWebViewReplyDto(
      replyId: reply.replyId,
      floor: reply.floor,
      html: rewritten.html,
      dateText: _formatReplyDate(reply.date),
      isPageStart: reply.floor % kRepliesPerPage == 1,
      authorUserId: reply.author.userId,
      nickname: reply.authorNickname,
      avatar: reply.author.avatar,
      gender: reply.author.gender,
      groupId: reply.author.groupId,
      youtubeIds: rewritten.youtubeIds,
      xIds: rewritten.xIds,
    );
  }

  RewrittenContentHtml rewriteContentHtml(
    String html, {
    bool leanPreview = false,
  }) {
    if (html.isEmpty) {
      return RewrittenContentHtml(html: html);
    }
    try {
      final document = parse('<div id="__root">$html</div>');
      final root = document.getElementById('__root');
      if (root == null) {
        return RewrittenContentHtml(html: html);
      }
      _applyColors(root);
      _convertIcons(root);
      if (leanPreview) {
        _replaceContentImagesWithPlaceholder(root);
      } else {
        _applyImageBoxes(root);
      }
      final youtubeIds = <String>[];
      final xIds = <String>[];
      if (!leanPreview) {
        _wrapLinkPreviews(root, youtubeIds: youtubeIds, xIds: xIds);
      }
      return RewrittenContentHtml(
        html: root.innerHtml,
        youtubeIds: youtubeIds,
        xIds: xIds,
      );
    } catch (_) {
      return RewrittenContentHtml(html: html);
    }
  }

  void _replaceContentImagesWithPlaceholder(Element root) {
    for (final el in List<Element>.from(root.querySelectorAll('img'))) {
      if (el.className.split(' ').contains('smiley')) {
        continue;
      }
      el.replaceWith(
        Element.tag('span')
          ..className = 'img-placeholder'
          ..text = kQuotePreviewImagePlaceholder,
      );
    }
  }

  void _applyColors(Element root) {
    for (final el in List<Element>.from(root.querySelectorAll('span.color'))) {
      final hex = el.attributes['hex'];
      if (hex == null || !_hexColor.hasMatch(hex)) {
        continue;
      }
      final normalized = hex.startsWith('#') ? hex : '#$hex';
      final existing = el.attributes['style'];
      el.attributes['style'] = existing == null || existing.isEmpty
          ? 'color:$normalized'
          : '$existing;color:$normalized';
    }
  }

  void _convertIcons(Element root) {
    for (final el in List<Element>.from(root.querySelectorAll('icon'))) {
      final src = el.attributes['src'] ?? '';
      final img = Element.tag('img')
        ..className = 'smiley'
        ..attributes['src'] = src
        ..attributes['alt'] = '';
      el.replaceWith(img);
    }
  }

  void _applyImageBoxes(Element root) {
    for (final el in List<Element>.from(root.querySelectorAll('img'))) {
      if (el.className.split(' ').contains('smiley')) {
        continue;
      }
      final classes = el.className.trim();
      el.className = classes.isEmpty ? 'content-img' : '$classes content-img';
      el.attributes['loading'] = 'lazy';

      final src = el.attributes['src'] ?? '';
      final sx = int.tryParse(el.attributes['data-sx'] ?? '');
      final sy = int.tryParse(el.attributes['data-sy'] ?? '');
      final styles = <String>[];
      if (sx != null && sx > 0) {
        styles.add('width:min(100%,${sx}px)');
        if (sy != null && sy > 0) {
          styles.add('aspect-ratio:$sx / $sy');
        }
      } else {
        styles.add('width:100%');
        final ratio = _aspectRatio(src);
        if (ratio != null && ratio > 0) {
          styles.add('aspect-ratio:${(1 / ratio).toStringAsFixed(5)}');
        } else {
          styles.add('aspect-ratio:4 / 3');
        }
      }
      final existing = el.attributes['style'];
      if (existing != null && existing.isNotEmpty) {
        styles.insert(0, existing);
      }
      el.attributes['style'] = styles.join(';');
    }
  }

  void _wrapLinkPreviews(
    Element root, {
    required List<String> youtubeIds,
    required List<String> xIds,
  }) {
    for (final anchor in List<Element>.from(root.querySelectorAll('a'))) {
      if (_closestClass(anchor, 'link-preview') != null) {
        continue;
      }
      final href = anchor.attributes['href'];
      if (href == null || href.isEmpty) {
        continue;
      }
      final videoId = YoutubeUrl.tryParseVideoId(href);
      if (videoId != null) {
        youtubeIds.add(videoId);
        _wrapPreview(
          anchor,
          kind: 'youtube',
          id: videoId,
          href: href,
          thumbUrl: YoutubeUrl.thumbnailUrl(videoId),
          subtitle: 'youtube.com',
        );
        continue;
      }
      final statusId = XUrl.tryParseStatusId(href);
      if (statusId != null) {
        xIds.add(statusId);
        _wrapPreview(
          anchor,
          kind: 'x',
          id: statusId,
          href: href,
          subtitle: 'x.com',
        );
      }
    }
  }

  void _wrapPreview(
    Element anchor, {
    required String kind,
    required String id,
    required String href,
    String? thumbUrl,
    required String subtitle,
  }) {
    final wrap = Element.tag('div')
      ..className = 'link-preview'
      ..attributes['data-preview'] = kind
      ..attributes['data-id'] = id
      ..attributes['data-href'] = href;

    anchor.replaceWith(wrap);
    wrap.append(anchor);

    final chip = Element.tag('button')
      ..className = 'preview-chip'
      ..attributes['type'] = 'button'
      ..attributes['data-href'] = href;

    final thumbClasses = StringBuffer('preview-thumb');
    if (thumbUrl != null) {
      thumbClasses.write(' has-image');
    } else if (kind == 'x') {
      thumbClasses.write(' preview-accent');
    }
    final thumb = Element.tag('div')..className = thumbClasses.toString();
    if (thumbUrl != null) {
      thumb.attributes['style'] =
          "background-image:url('${thumbUrl.replaceAll("'", '%27')}')";
    }
    if (kind == 'youtube') {
      thumb.append(Element.tag('div')..className = 'preview-play');
    }

    final body = Element.tag('div')..className = 'preview-body';
    body.append(Element.tag('div')
      ..className = 'preview-title'
      ..text = 'Loading…');
    if (kind == 'x') {
      body.append(Element.tag('div')..className = 'preview-text');
    }
    body.append(Element.tag('div')
      ..className = 'preview-sub'
      ..text = subtitle);

    chip.append(thumb);
    chip.append(body);
    wrap.append(chip);
  }

  Element? _closestClass(Element start, String className) {
    Element? current = start;
    while (current != null) {
      if (current.className.split(' ').contains(className)) {
        return current;
      }
      final parent = current.parent;
      current = parent is Element ? parent : null;
    }
    return null;
  }

  double? _aspectRatio(String url) {
    if (aspectRatioFor != null) {
      return aspectRatioFor!(url);
    }
    try {
      return ImageAspectRatioStore.instance.aspectRatio(url);
    } catch (_) {
      return null;
    }
  }
}
