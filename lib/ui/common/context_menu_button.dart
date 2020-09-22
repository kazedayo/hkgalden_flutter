import 'dart:ui';

import 'package:flutter/material.dart';

class ContextMenuButton extends StatefulWidget {
  final double height;
  final double width;
  final double xOffset;
  final double yOffset;
  final Widget child;
  final Widget closedChild;
  final ContextMenuButtonController controller;
  final Function onBarrierDismiss;

  const ContextMenuButton(
      {Key key,
      @required this.height,
      @required this.width,
      @required this.xOffset,
      @required this.yOffset,
      @required this.child,
      @required this.closedChild,
      @required this.controller,
      this.onBarrierDismiss})
      : super(key: key);

  @override
  _ContextMenuButtonState createState() => _ContextMenuButtonState(controller);
}

class _ContextMenuButtonState extends State<ContextMenuButton>
    with SingleTickerProviderStateMixin {
  bool _isMenuShowing;
  OverlayEntry _overlayEntry;
  OverlayEntry _backgroundOverlayEntry;
  final LayerLink _layerLink = LayerLink();
  AnimationController _animationController;

  _ContextMenuButtonState(ContextMenuButtonController _controller) {
    _controller.toggleMenu = toggleMenu;
  }

  @override
  void initState() {
    _isMenuShowing = false;
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150))
          ..addStatusListener((status) {
            if (status == AnimationStatus.dismissed) {
              _backgroundOverlayEntry.remove();
              _overlayEntry.remove();
            }
          });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleMenu() {
    if (_isMenuShowing) {
      _isMenuShowing = false;
      _animationController.reverse();
    } else {
      _overlayEntry = _create();
      _backgroundOverlayEntry = _createBackground();
      Overlay.of(context).insert(_backgroundOverlayEntry);
      Overlay.of(context).insert(_overlayEntry);
      _isMenuShowing = true;
      _animationController.forward();
    }
  }

  OverlayEntry _createBackground() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () {
          toggleMenu();
          if (widget.onBarrierDismiss != null) widget.onBarrierDismiss();
        },
        child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Container(
                  color: Colors.black
                      .withOpacity(_animationController.value * 0.5),
                )),
      ),
    );
  }

  OverlayEntry _create() {
    RenderBox renderBox = context.findRenderObject();
    var size = renderBox.size;

    return OverlayEntry(
        builder: (context) => AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Positioned(
                width: widget.width,
                height: widget.height,
                child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(
                        widget.xOffset,
                        Tween(
                                begin: size.height - 10,
                                end: size.height + widget.yOffset)
                            .animate(_animationController)
                            .value),
                    child: Opacity(
                        opacity: _animationController.value,
                        child: Material(
                          color: Colors.white,
                          elevation: 6,
                          borderRadius: BorderRadius.circular(6),
                          child: widget.child,
                        ))),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
        link: _layerLink,
        child: widget.closedChild,
      );
}

class ContextMenuButtonController {
  void Function() toggleMenu;
}
