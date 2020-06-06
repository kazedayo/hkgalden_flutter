import 'package:flutter/material.dart';

class ThreadCell extends StatelessWidget {
final String _title;

ThreadCell(this._title);

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.face, size: 15),
              SizedBox(width: 5),
              Text('user1'),
              SizedBox(width: 10),
              Icon(Icons.reply, size: 15),
              SizedBox(width: 5),
              Text('xx'),
              SizedBox(width: 10),
              Icon(Icons.access_time, size: 15),
              SizedBox(width: 5),
              Text('xx minutes'),
            ],
          ),
        ],
      ),
    );
}