import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/viewmodels/home_drawer_view_model.dart';

import '../../redux/app/app_state.dart';

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
            Container(
              height: 250,
              child: DrawerHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child: Icon(Icons.account_circle, size: 50,),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xff7435a0),Color(0xff4a72d3)],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'User Name',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    RaisedButton(
                      onPressed: () => null,
                      child: Text('Logout'),
                      color: Colors.redAccent[400],
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                ),
              ),
            ),
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