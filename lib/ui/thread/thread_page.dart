import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/ui/common/page_end_loading_indicator.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:hkgalden_flutter/viewmodels/thread_page_view_model.dart';
import 'package:marquee_widget/marquee_widget.dart';

class ThreadPage extends StatefulWidget {
  final String title;
  final int threadId;

  const ThreadPage({Key key, this.title, this.threadId}) : super(key: key);

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  AnimationController _fabAnimationController;

  @override
  void initState() {
    _scrollController = ScrollController()..addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        print('scroll view hit bottom!');
        if ((store.state.threadState.thread.totalReplies.toDouble() / 50.0).ceil() > store.state.threadState.currentPage) {
          print('loading page ${store.state.threadState.currentPage + 1}');
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
    })..addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        _fabAnimationController.reverse();
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        _fabAnimationController.forward();
      }
    });
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 100),
      value: 1,
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) => StoreConnector<AppState, ThreadPageViewModel>(
    converter: (store) => ThreadPageViewModel.create(store),
    builder: (BuildContext context, ThreadPageViewModel viewModel) => Scaffold(
      appBar: AppBar(
        title: Marquee(
          child: Text(widget.title, style: TextStyle(fontWeight: FontWeight.w700)),
          animationDuration: Duration(seconds: 5),
          pauseDuration: Duration(seconds: 2),
          backDuration: Duration(seconds: 5),
        ),
        bottom: PreferredSize(
          child: SizedBox(
            height: 3, 
            child: Visibility(
              visible: viewModel.isLoading && !viewModel.isInitialLoad,
              child: LinearProgressIndicator()
            ),
          ), 
          preferredSize: Size(double.infinity,3),
        ),
      ),
      body: viewModel.isLoading && viewModel.isInitialLoad ? 
        Center(
          child: CircularProgressIndicator(),
        ) : 
        ListView(
          controller: _scrollController,
          children: _generateReplies(viewModel),
        ),
      floatingActionButton: FadeTransition(
        opacity: _fabAnimationController,
        child: ScaleTransition(
          scale: _fabAnimationController,
          child: FloatingActionButton(
            child: Icon(Icons.reply),
            onPressed: null,
          ),
        ),
      ),
    ),
  );

  List<Widget> _generateReplies(ThreadPageViewModel viewModel) {
    List<Widget> repliesWidgets = [];
    for (Reply reply in viewModel.replies) {
      if (reply.floor % 50 == 1) {
        repliesWidgets.add(Container(
          height: 50,
          child: Center(
            child: Text(reply.floor == 1 ? '第 1 頁' : '第 ${((reply.floor + 49) ~/ 50)} 頁'),
          ),
        ));
      }
      repliesWidgets.add(
        Visibility(
          visible: !viewModel.blockedUserIds.contains(reply.author.userId),
          child: CommentCell(reply: reply)
        ),
      );
    }
    repliesWidgets.add((viewModel.totalReplies.toDouble() / 50.0).ceil() > viewModel.currentPage ? 
      PageEndLoadingInidicator(): 
      Container(
        height: 50,
        child: Center(
          child: Text('已到post底', style: TextStyle(color: Colors.grey)),
        ),
      )
    );
    return repliesWidgets;
  }
}