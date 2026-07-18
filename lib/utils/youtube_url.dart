abstract final class YoutubeUrl {
  static final RegExp _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  static String? tryParseVideoId(String? url) {
    if (url == null) {
      return null;
    }
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on FormatException {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    final host = uri.host.toLowerCase();
    final bareHost = host.startsWith('www.') ? host.substring(4) : host;

    if (bareHost == 'youtu.be') {
      if (uri.pathSegments.isEmpty) {
        return null;
      }
      return _validId(uri.pathSegments.first);
    }

    const youtubeHosts = {
      'youtube.com',
      'm.youtube.com',
      'music.youtube.com',
      'youtube-nocookie.com',
    };
    if (!youtubeHosts.contains(bareHost)) {
      return null;
    }

    final fromQuery = uri.queryParameters['v'];
    if (fromQuery != null) {
      return _validId(fromQuery);
    }

    final segments = uri.pathSegments;
    if (segments.length >= 2) {
      final kind = segments.first.toLowerCase();
      if (kind == 'embed' ||
          kind == 'shorts' ||
          kind == 'live' ||
          kind == 'v') {
        return _validId(segments[1]);
      }
    }

    return null;
  }

  static String? _validId(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final cleaned = raw.split(RegExp(r'[?&#/]')).first;
    if (_videoIdPattern.hasMatch(cleaned)) {
      return cleaned;
    }
    return null;
  }

  static String thumbnailUrl(String videoId) =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

  static String watchUrl(String videoId) =>
      'https://www.youtube.com/watch?v=$videoId';
}
