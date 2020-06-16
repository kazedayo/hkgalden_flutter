import 'package:flutter/material.dart';

class HomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
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
            flex: 1,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 0),
              itemCount: 16,
              itemBuilder: (context, index) => ListTile(
                title: Text('Channel $index'),
                trailing: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}