import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/ui/home/drawer/channel_cell.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer_header.dart';
import 'package:hkgalden_flutter/viewmodels/home/drawer/home_drawer_view_model.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';

class HomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, HomeDrawerViewModel>(
        converter: (store) => HomeDrawerViewModel.create(store),
        builder: (BuildContext context, HomeDrawerViewModel viewModel) =>
            Container(
          width: 200,
          child: Drawer(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                HomeDrawerHeader(),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: SafeArea(
                      top: false,
                      child: ListView.builder(
                        key: PageStorageKey('channelListView'),
                        padding: EdgeInsets.symmetric(vertical: 10),
                        itemCount: viewModel.channels.length,
                        itemBuilder: (context, index) =>
                            ChannelCell(viewModel: viewModel, index: index),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
