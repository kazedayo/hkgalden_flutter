import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/comment_cell.dart';

class ThreadPage extends StatelessWidget {
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Thread'),
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