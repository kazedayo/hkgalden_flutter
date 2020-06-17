import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:marquee_widget/marquee_widget.dart';

class ThreadPage extends StatelessWidget {
  final String title;

  const ThreadPage({Key key, this.title}) : super(key: key);

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: SizedBox(
        height: 30, 
        child: Marquee(
          child: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
          animationDuration: Duration(seconds: 5),
          backDuration: Duration(seconds: 5),
          pauseDuration: Duration(seconds: 1),
          directionMarguee: DirectionMarguee.TwoDirection,
        )
      ),
    ),
    body: ListView(
      children: List.generate(30, (index) => CommentCell()),
    ),
    floatingActionButton: FloatingActionButton(
      child: Icon(Icons.reply),
      onPressed: null,
    ),
  );
}