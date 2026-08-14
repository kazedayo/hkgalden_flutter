import 'package:flutter/scheduler.dart';

/// `localToGlobal` / `RenderBox.size` is unsafe while Flutter is laying out.
///
/// Image loads during trailing-edge restore fire scroll metrics from
/// [RenderViewport.performLayout]; walking up through `Transform.translate`
/// then hits `RenderFractionalTranslation.applyPaintTransform`.
bool threadCanReadPaintGeometry() {
  return SchedulerBinding.instance.schedulerPhase !=
      SchedulerPhase.persistentCallbacks;
}
