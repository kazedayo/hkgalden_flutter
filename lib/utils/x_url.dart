abstract final class XUrl {
  static final RegExp _statusIdPattern = RegExp(r'^\d+$');

  static const Set<String> _hosts = {
    'x.com',
    'www.x.com',
    'mobile.x.com',
    'twitter.com',
    'www.twitter.com',
    'mobile.twitter.com',
  };

  /// Returns the numeric status/post id, or null if [url] is not an X post URL.
  static String? tryParseStatusId(String? url) {
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
    if (!_hosts.contains(host)) {
      return null;
    }

    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      return null;
    }

    // /{user}/status/{id}
    if (segments.length >= 3 &&
        segments[1].toLowerCase() == 'status') {
      return _validId(segments[2]);
    }

    // /i/web/status/{id}
    if (segments.length >= 4 &&
        segments[0].toLowerCase() == 'i' &&
        segments[1].toLowerCase() == 'web' &&
        segments[2].toLowerCase() == 'status') {
      return _validId(segments[3]);
    }

    // /i/status/{id}
    if (segments.length >= 3 &&
        segments[0].toLowerCase() == 'i' &&
        segments[1].toLowerCase() == 'status') {
      return _validId(segments[2]);
    }

    return null;
  }

  static String? _validId(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final cleaned = raw.split(RegExp(r'[?&#/]')).first;
    if (_statusIdPattern.hasMatch(cleaned)) {
      return cleaned;
    }
    return null;
  }
}
