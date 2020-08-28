import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info/package_info.dart';

class MenuButton extends StatefulWidget {
  @override
  _MenuButtonState createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton>
    with SingleTickerProviderStateMixin {
  bool _isMenuShowing;
  OverlayEntry _overlayEntry;
  OverlayEntry _backgroundOverlayEntry;
  final LayerLink _layerLink = LayerLink();
  AnimationController _animationController;

  @override
  void initState() {
    _isMenuShowing = false;
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150))
          ..addStatusListener((status) {
            if (status == AnimationStatus.dismissed) {
              _overlayEntry.remove();
              _backgroundOverlayEntry.remove();
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
        onTap: () => toggleMenu(),
        child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: _animationController.value * 5,
                      sigmaY: _animationController.value * 5),
                  child: Container(
                    color: Colors.black
                        .withOpacity(_animationController.value * 0.5),
                  ),
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
                width: 200,
                child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(
                        -160,
                        Tween(begin: size.height - 20, end: size.height)
                            .animate(_animationController)
                            .value),
                    child: Opacity(
                        opacity: _animationController.value,
                        child: Material(
                          color: Colors.white,
                          elevation: 6,
                          borderRadius: BorderRadius.circular(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                  icon: Icon(
                                    Icons.account_box,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () {
                                    toggleMenu();
                                    Navigator.of(context)
                                        .pushNamed('/SessionUser');
                                  }),
                              IconButton(
                                  icon: Icon(
                                    Icons.settings,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () async {
                                    toggleMenu();
                                    PackageInfo info =
                                        await PackageInfo.fromPlatform();
                                    showModal(
                                      context: context,
                                      builder: (context) => Theme(
                                        data: ThemeData.light(),
                                        child: AboutDialog(
                                          applicationName: 'hkGalden',
                                          applicationIcon: SvgPicture.asset(
                                            'assets/icon-hkgalden.svg',
                                            width: 50,
                                            height: 50,
                                            color:
                                                Theme.of(context).accentColor,
                                          ),
                                          applicationVersion:
                                              '${info.version}+${info.buildNumber}',
                                          applicationLegalese:
                                              '© hkGalden & 1080',
                                        ),
                                      ),
                                    );
                                  }),
                              IconButton(
                                  icon: Icon(
                                    Icons.exit_to_app,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    toggleMenu();
                                    //viewModel.onLogout();
                                  }),
                              IconButton(
                                  icon: Icon(
                                    Icons.block,
                                    color: Colors.black87,
                                  ),
                                  onPressed: () => null),
                            ],
                          ),
                        ))),
              ),
            ));
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
        link: _layerLink,
        child: IconButton(
            icon: Icon(Icons.apps),
            onPressed: () {
              toggleMenu();
            }),
      );
}
