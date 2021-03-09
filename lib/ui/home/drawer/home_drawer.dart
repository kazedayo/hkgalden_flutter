import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/ui/home/drawer/channel_cell.dart';
import 'package:hkgalden_flutter/viewmodels/home/drawer/home_drawer_view_model.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';

class HomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, HomeDrawerViewModel>(
        distinct: true,
        converter: (store) => HomeDrawerViewModel.create(store),
        builder: (BuildContext context, HomeDrawerViewModel viewModel) =>
            GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140, childAspectRatio: 2),
          itemBuilder: (context, index) => ChannelCell(
            viewModel: viewModel,
            channel: viewModel.channels[index],
          ),
          itemCount: viewModel.channels.length,
        ),
      );
}
