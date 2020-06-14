import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/compose_page.dart';
import 'package:hkgalden_flutter/ui/thread_cell.dart';
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
        builder: (BuildContext context, HomePageViewModel viewModel) => ListView.separated(
          separatorBuilder: (context, index) => Divider(indent: 8,height: 1,thickness: 1,),
          itemCount: viewModel.threads.length,
          itemBuilder: (context, index) => InkWell(
            child: ThreadCell(
              title: viewModel.threads[index].title,
              authorName: viewModel.threads[index].authorName,
              totalReplies: viewModel.threads[index].totalReplies,
              lastReply: viewModel.threads[index].lastReply,
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ThreadPage())),
          ),
        ),
      ),
      drawer: Container(
        width: 200,
        child: Drawer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
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
                        'User Name',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      RaisedButton(
                        onPressed: () => null,
                        child: Text('Logout'),
                        color: Colors.redAccent[400],
                      ),
                    ],
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  childAspectRatio: 2,
                  children: List.generate(30, (index) => Center(
                    child: Text(
                      'Channel $index'
                    ),
                  ))
                ),
              ),
            ],
          ),
        ),
      ),
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