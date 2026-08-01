import 'package:hkgalden_flutter/models/smiley_pack.dart';

/// Default pack id used by the web editor when available.
const String kDefaultSmileyPackId = 'hkg';

/// Picks the initial pack id: [kDefaultSmileyPackId] when present, else first pack.
String? selectDefaultSmileyPackId(List<SmileyPack> packs) {
  if (packs.isEmpty) return null;
  for (final pack in packs) {
    if (pack.id == kDefaultSmileyPackId) {
      return pack.id;
    }
  }
  return packs.first.id;
}

SmileyPack? findSmileyPackById(List<SmileyPack> packs, String? packId) {
  if (packId == null) return null;
  for (final pack in packs) {
    if (pack.id == packId) return pack;
  }
  return null;
}
