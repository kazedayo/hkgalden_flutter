import 'package:flutter/material.dart';

class StopScrollOnInactive extends StatefulWidget {
  final Widget child;

  const StopScrollOnInactive({super.key, required this.child});

  @override
  State<StopScrollOnInactive> createState() => _StopScrollOnInactiveState();
}

class _StopScrollOnInactiveState extends State<StopScrollOnInactive>
    with WidgetsBindingObserver {
  BuildContext? _scrollContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      return;
    }
    final ctx = _scrollContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    final position = Scrollable.maybeOf(ctx)?.position;
    if (position != null && position.hasPixels) {
      position.jumpTo(position.pixels);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _scrollContext = notification.context;
        return false;
      },
      child: widget.child,
    );
  }
}
