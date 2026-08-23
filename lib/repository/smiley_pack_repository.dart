import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/utils/inflight_cache.dart';

class SmileyPackRepository {
  SmileyPackRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;
  final InflightCache<int, List<SmileyPack>?> _cache = InflightCache();

  /// Last successful fetch, or empty when nothing has been loaded yet.
  List<SmileyPack> get cachedPacks => _cache.peek(0) ?? const [];

  /// Returns cached packs when present; otherwise fetches (coalescing in-flight).
  Future<List<SmileyPack>?> getInstalledPacks() {
    return _cache.get(0, fetchInstalledPacks, cacheNulls: false);
  }

  /// Fire-and-forget fetch so compose can read [cachedPacks] immediately.
  void prewarm() {
    getInstalledPacks();
  }

  void clearCache() {
    _cache.clear();
  }

  Future<List<SmileyPack>?> fetchInstalledPacks() =>
      _api.getInstalledPacksQuery();
}
