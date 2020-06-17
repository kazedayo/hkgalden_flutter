import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer_header.dart';
import 'package:hkgalden_flutter/viewmodels/home_drawer_view_model.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';

class HomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StoreConnector<AppState, HomeDrawerViewModel>(
    converter: (store) => HomeDrawerViewModel.create(store),
    builder: (BuildContext context, HomeDrawerViewModel viewModel) => Container(
      width: 200,
      child: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            HomeDrawerHeader(),
            Expanded(
              child: SafeArea(
                top: false,
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 0),
                  itemCount: viewModel.channels.length,
                  itemBuilder: (context, index) => ListTile(
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
                    } ,
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