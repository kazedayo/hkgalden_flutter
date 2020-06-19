import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:hkgalden_flutter/viewmodels/thread_page_view_model.dart';
import 'package:marquee_widget/marquee_widget.dart';

class ThreadPage extends StatelessWidget {
  final String title;
  final int threadId;

  const ThreadPage({Key key, this.title, this.threadId}) : super(key: key);

  @override Widget build(BuildContext context) => StoreConnector<AppState, ThreadPageViewModel>(
    converter: (store) => ThreadPageViewModel.create(store),
    builder: (BuildContext context, ThreadPageViewModel viewModel) => Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 30, 
          child: Marquee(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
            animationDuration: Duration(seconds: 5),
            backDuration: Duration(seconds: 5),
            pauseDuration: Duration(seconds: 1),
            directionMarguee: DirectionMarguee.TwoDirection,
          ),
        ),
      ),
      body: viewModel.isLoading ? 
      Center(
        child: CircularProgressIndicator(),
      ) : 
      ListView.builder(
        itemCount: viewModel.replies.length,
        itemBuilder: (context, index) => CommentCell(reply: viewModel.replies[index]),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.reply),
        onPressed: null,
      ),
    ),
  );
}