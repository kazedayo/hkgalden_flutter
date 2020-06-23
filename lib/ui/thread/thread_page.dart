import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
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
  AnimationController _appBarElevationAnimationController;
  Animation<double> _appBarElevationAnimation;
  AnimationController _linearProgressIndicatorAnimationController;

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
    })..addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.minScrollExtent) {
        _appBarElevationAnimationController.forward();
      } else if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) {
        _appBarElevationAnimationController.reverse();
      }
    });
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 100),
      value: 1,
      vsync: this,
    );
    _appBarElevationAnimationController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _appBarElevationAnimation = Tween<double>(begin: 0, end: Theme.of(context).appBarTheme.elevation).animate(_appBarElevationAnimationController);
    _linearProgressIndicatorAnimationController = AnimationController(
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
    _appBarElevationAnimationController.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) => StoreConnector<AppState, ThreadPageViewModel>(
    converter: (store) => ThreadPageViewModel.create(store),
    onDidChange: (viewModel) => 
      viewModel.isLoading && !viewModel.isInitialLoad ? 
        _linearProgressIndicatorAnimationController.forward() : 
        _linearProgressIndicatorAnimationController.reverse(),
    builder: (BuildContext context, ThreadPageViewModel viewModel) => Scaffold(
      appBar: AppBar(
        title: Container(
          child: Marquee(
            child: Text(widget.title, style: TextStyle(fontWeight: FontWeight.w700)),
            animationDuration: Duration(seconds: 5),
            backDuration: Duration(seconds: 5),
            pauseDuration: Duration(seconds: 1),
            directionMarguee: DirectionMarguee.TwoDirection,
          ),
        ),
        bottom: PreferredSize(
          child: SizedBox(
            height: 3, 
            child: FadeTransition(
              opacity: _linearProgressIndicatorAnimationController,
              child: LinearProgressIndicator(
                backgroundColor: Colors.greenAccent[900],
              ),
            ),
          ), 
          preferredSize: Size(double.infinity,3),
        ),
        elevation: _appBarElevationAnimation.value,
      ),
      body: viewModel.isLoading && viewModel.isInitialLoad ? 
      Center(
        child: CircularProgressIndicator(),
      ) : 
      ListView(
        controller: _scrollController,
        children: viewModel.onLoadReplies(),
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
}