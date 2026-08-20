import 'package:hkgalden_flutter/models/smiley_pack.dart';

const String kDefaultSmileyPackId = 'hkg';

String? selectDefaultSmileyPackId(List<SmileyPack> packs) {
  if (packs.isEmpty) return null;
  return (packs.where((p) => p.id == kDefaultSmileyPackId).firstOrNull ??
          packs.first)
      .id;
}

SmileyPack? findSmileyPackById(List<SmileyPack> packs, String? packId) =>
    packId == null ? null : packs.where((p) => p.id == packId).firstOrNull;
