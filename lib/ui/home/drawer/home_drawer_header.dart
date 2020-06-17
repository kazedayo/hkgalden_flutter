import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/login_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';

class HomeDrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
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
            '未登入',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          RaisedButton(
            onPressed: () => Navigator.push(context, SlideInFromBottomRoute(page: LoginPage())),
            child: Text('登入'),
            color: Colors.green[700],
          ),
        ],
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
      ),
    ),
  );
}