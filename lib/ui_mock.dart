import 'package:flutter/material.dart';
import 'startup_animation.dart';
import 'comment_cell.dart';
import 'compose_page.dart';
import 'thread_cell.dart';

class MyHomePage extends StatelessWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => Divider(indent: 8,height: 1,thickness: 1,),
        itemCount: 30,
        itemBuilder: (context, index) => InkWell(
          child: ThreadCell(
            'Thread #$index'
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ThreadPage())),
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
                      Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 50,
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
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StartupScreen())),
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