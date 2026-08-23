import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hkgalden_flutter/models/smiley.dart';
import 'package:hkgalden_flutter/models/smiley_pack.dart';

const String kDefaultSmileyPackId = 'hkg';

String smileyGifUrl({
  required String packId,
  required String smileyId,
}) =>
    'https://s.hkgalden.org/smilies/$packId/$smileyId.gif';

String? selectDefaultSmileyPackId(List<SmileyPack> packs) {
  if (packs.isEmpty) return null;
  return (packs.where((p) => p.id == kDefaultSmileyPackId).firstOrNull ??
          packs.first)
      .id;
}

SmileyPack? findSmileyPackById(List<SmileyPack> packs, String? packId) =>
    packId == null ? null : packs.where((p) => p.id == packId).firstOrNull;

/// Quill embed type and payload for Galden smilies (matches web insert attrs).
abstract final class SmileyEmbed {
  static const String type = 'smiley';

  /// Payload stored under insert key [type] in the document delta.
  static Map<String, dynamic> payload(String packId, Smiley smiley) => {
        'id': smiley.id,
        'packId': packId,
        'width': smiley.width,
        'height': smiley.height,
        'alt': smiley.alt,
      };

  static Embeddable create(String packId, Smiley smiley) =>
      Embeddable(type, payload(packId, smiley));

  /// Inserts an inline smiley at the current selection via the Quill controller.
  static void insertInto(
    QuillController controller,
    String packId,
    Smiley smiley,
  ) {
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;
    final safeIndex = index < 0 ? 0 : index;
    final safeLength = length < 0 ? 0 : length;
    controller.replaceText(
      safeIndex,
      safeLength,
      create(packId, smiley),
      null,
    );
    controller.updateSelection(
      TextSelection.collapsed(offset: safeIndex + 1),
      ChangeSource.local,
    );
  }
}
