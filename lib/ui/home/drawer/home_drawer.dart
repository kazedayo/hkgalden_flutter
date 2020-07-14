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
            Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HomeDrawerHeader(),
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 2.6),
              itemCount: viewModel.channels.length,
              itemBuilder: (context, index) =>
                  ChannelCell(viewModel: viewModel, index: index),
            ),
          ],
        ),
      );
}
