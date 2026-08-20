import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class SmileyPackRepository {
  SmileyPackRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;
  List<SmileyPack>? _cached;
  Future<List<SmileyPack>?>? _inFlight;
  int _generation = 0;

  /// Last successful fetch, or empty when nothing has been loaded yet.
  List<SmileyPack> get cachedPacks => _cached ?? const [];

  /// Returns cached packs when present; otherwise fetches (coalescing in-flight).
  Future<List<SmileyPack>?> getInstalledPacks() {
    final cached = _cached;
    if (cached != null) return Future<List<SmileyPack>?>.value(cached);

    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final generation = _generation;
    late final Future<List<SmileyPack>?> future;
    future = fetchInstalledPacks().then((packs) {
      if (generation != _generation) return packs;
      if (packs != null) {
        _cached = packs;
      }
      return packs;
    }).whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
    _inFlight = future;
    return future;
  }

  /// Fire-and-forget fetch so compose can read [cachedPacks] immediately.
  void prewarm() {
    getInstalledPacks();
  }

  void clearCache() {
    _generation++;
    _cached = null;
    _inFlight = null;
  }

  Future<List<SmileyPack>?> fetchInstalledPacks() =>
      _api.getInstalledPacksQuery();
}
