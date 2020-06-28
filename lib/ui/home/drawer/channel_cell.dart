import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/viewmodels/home_drawer_view_model.dart';

class ChannelCell extends StatelessWidget {
  final HomeDrawerViewModel viewModel;
  final int index;

  const ChannelCell({Key key, this.viewModel, this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.symmetric(horizontal: 8),
    child: ListTile(
      title: Text(viewModel.channels[index].channelName),
      trailing: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: viewModel.channels[index].channelColor,
          shape: BoxShape.circle,
        ),
      ),
      onTap: () {
        viewModel.onTap(viewModel.channels[index].channelId);
        Navigator.pop(context);
      },
      selected: false,
    ),
    decoration: BoxDecoration(
      color: viewModel.selectedChannelId == viewModel.channels[index].channelId ? 
      Theme.of(context).splashColor : 
      Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.all(Radius.circular(5))
    ),    
  );
}