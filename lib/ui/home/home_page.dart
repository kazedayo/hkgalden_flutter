import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/ui/home/compose_page.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/viewmodels/home_page_view_model.dart';

class HomePage extends StatefulWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  AnimationController _fabAnimationController;

  @override
  void initState() {
    _scrollController = ScrollController()..addListener(() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        store.dispatch(
        RequestThreadListAction(
            channelId: store.state.threadListState.currentChannelId, 
            page: store.state.threadState.currentPage + 1, 
            isRefresh: true
          )
        );
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

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, HomePageViewModel>(
      converter: (store) => HomePageViewModel.create(store),
      distinct: true,
      builder: (BuildContext context, HomePageViewModel viewModel) => Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Spacer(flex: 1),
              Hero(tag: 'logo', child: SizedBox(child: SvgPicture.asset('assets/icon-hkgalden.svg'), width: 27, height: 27)),
              SizedBox(width: 5),
              Text(viewModel.title, style: TextStyle(fontWeight: FontWeight.w700), strutStyle: StrutStyle(height:1.25)),
              Spacer(flex: 2),
            ],
          ),
          //leading: SvgPicture.asset('assets/icon-hkgalden.svg'),
        ),
        body: viewModel.isThreadLoading && viewModel.isRefresh == false ? 
          Center(
            child: CircularProgressIndicator(),
          ) : 
          RefreshIndicator(
          onRefresh: () => viewModel.onRefresh(viewModel.selectedChannelId),
          child: ListView(
            controller: _scrollController,
            children: viewModel.onLoadThreadList(context),
          ),
        ),
        drawer: HomeDrawer(),
        floatingActionButton: FadeTransition(
          opacity: _fabAnimationController,
          child: ScaleTransition(
            scale: _fabAnimationController,
            child: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(SlideInFromBottomRoute(page: ComposePage())),
              child: Icon(Icons.create),
            ),
          ),
        )
      ),
    );
  }
}