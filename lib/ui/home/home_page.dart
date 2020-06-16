import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/home/compose_page.dart';
import 'package:hkgalden_flutter/ui/home/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/thread_page.dart';
import 'package:hkgalden_flutter/viewmodels/home_page_view_model.dart';

class HomePage extends StatelessWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StoreConnector<AppState, HomePageViewModel>(
        converter: (store) => HomePageViewModel.create(store),
        builder: (BuildContext context, HomePageViewModel viewModel) => RefreshIndicator(
          onRefresh: () => viewModel.onRefresh(),
          child: ListView.separated(
            separatorBuilder: (context, index) => Divider(indent: 8,height: 1,thickness: 1,),
            itemCount: viewModel.threads.length,
            itemBuilder: (context, index) => InkWell(
              child: ThreadCell(
                title: viewModel.threads[index].title,
                authorName: viewModel.threads[index].replies[0].authorNickname,
                totalReplies: viewModel.threads[index].totalReplies,
                lastReply: viewModel.threads[index].replies.length == 2 ? 
                            viewModel.threads[index].replies[1].date : 
                            viewModel.threads[index].replies[0].date,
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ThreadPage())),
            ),
          ),
        ),
      ),
      drawer: HomeDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(_createRoute()),
        child: Icon(Icons.create),
      ),
    );
  }
}

Route _createRoute() => PageRouteBuilder(
  pageBuilder: (context, animation, secondaryAnimation) => ComposePage(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    var begin = Offset(0.0,1.0);
    var end = Offset.zero;
    var curve = Curves.easeOut;
    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);
    return SlideTransition(position: offsetAnimation, child: child);
  },
);