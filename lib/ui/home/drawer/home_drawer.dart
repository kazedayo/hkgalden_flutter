import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/ui/home/drawer/channel_cell.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer_header.dart';
import 'package:hkgalden_flutter/ui/user_detail/session_user_detail_view.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/viewmodels/home/drawer/home_drawer_view_model.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';

class HomeDrawer extends StatefulWidget {
  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  bool _showSubPage;

  @override
  void initState() {
    _showSubPage = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, HomeDrawerViewModel>(
        distinct: true,
        converter: (store) => HomeDrawerViewModel.create(store),
        builder: (BuildContext context, HomeDrawerViewModel viewModel) =>
            Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HomeDrawerHeader(onAvatarTap: () {
              setState(() {
                _showSubPage = !_showSubPage;
              });
            }),
            PageTransitionSwitcher(
              duration: const Duration(milliseconds: 300),
              reverse: !_showSubPage,
              transitionBuilder: (
                Widget child,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return SharedAxisTransition(
                  child: child,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              child: _showSubPage
                  ? SessionUserDetailView()
                  : GridView.count(
                      padding: EdgeInsets.only(bottom: 10),
                      key: drawerKey,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      children: viewModel.channels
                          .map((channel) => ChannelCell(
                              viewModel: viewModel, channel: channel))
                          .toList(),
                    ),
            ),
          ],
        ),
      );
}
