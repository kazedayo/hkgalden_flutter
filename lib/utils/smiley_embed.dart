import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hkgalden_flutter/models/smiley.dart';

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

  /// Delta op shape produced by the real editor after [insertInto].
  static Map<String, dynamic> toDeltaOp(String packId, Smiley smiley) => {
        'insert': {type: payload(packId, smiley)},
      };

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
