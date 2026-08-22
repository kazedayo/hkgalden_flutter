import 'package:flutter/foundation.dart';

class ThreadPageUi {
  final onLastPage = ValueNotifier(false);
  final canReply = ValueNotifier(false);
  final elevation = ValueNotifier(0.0);
  void dispose() {
    onLastPage.dispose();
    canReply.dispose();
    elevation.dispose();
  }
}
