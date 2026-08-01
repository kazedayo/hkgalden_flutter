import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class SmileyPackRepository {
  SmileyPackRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;

  Future<List<SmileyPack>?> getInstalledPacks() =>
      _api.getInstalledPacksQuery();
}
