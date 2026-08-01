/// CDN helpers for hkgalden smiley GIFs (same host/path as web).
String smileyGifUrl({
  required String packId,
  required String smileyId,
}) =>
    'https://s.hkgalden.org/smilies/$packId/$smileyId.gif';
