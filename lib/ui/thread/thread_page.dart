import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/viewmodels/thread_page_view_model.dart';
import 'package:marquee_widget/marquee_widget.dart';

class ThreadPage extends StatelessWidget {
  final String title;
  final int threadId;
  static final ScrollController _scrollController = ScrollController()..addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        print('scroll view hit bottom!');
        if ((store.state.threadState.thread.totalReplies.toDouble() / 50.0).ceil() > store.state.threadState.currentPage) {
          store.dispatch(
            RequestThreadAction(
              threadId: store.state.threadState.thread.threadId,
              page: store.state.threadState.currentPage + 1,
              isInitialLoad: false,
            )
          );
        } else {
          print('This is the last page of this thread!');
        }
      }
    });

  const ThreadPage({Key key, this.title, this.threadId}) : super(key: key);

  @override Widget build(BuildContext context) => StoreConnector<AppState, ThreadPageViewModel>(
    converter: (store) => ThreadPageViewModel.create(store),
    builder: (BuildContext context, ThreadPageViewModel viewModel) => Scaffold(
      appBar: AppBar(
        title: Container(
          child: Marquee(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
            animationDuration: Duration(seconds: 5),
            backDuration: Duration(seconds: 5),
            pauseDuration: Duration(seconds: 1),
            directionMarguee: DirectionMarguee.TwoDirection,
          ),
        ),
        bottom: PreferredSize(
          child: SizedBox(
            height: 1, 
            child: viewModel.isLoading && !viewModel.isInitialLoad ? LinearProgressIndicator() : SizedBox(),
          ), 
          preferredSize: Size(double.infinity,3),
        )
      ),
      body: viewModel.isLoading && viewModel.isInitialLoad ? 
      Center(
        child: CircularProgressIndicator(),
      ) : 
      ListView(
        controller: _scrollController,
        children: viewModel.onLoadReplies(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.reply),
        onPressed: null,
      ),
    ),
  );
}