import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/ui/user_detail/block_list_page.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/utils/keys.dart';

class SessionUserDetailView extends StatefulWidget {
  @override
  _SessionUserDetailViewState createState() => _SessionUserDetailViewState();
}

class _SessionUserDetailViewState extends State<SessionUserDetailView> {
  List<Widget> _pages = [
    BlockListPage(),
    UserThreadListPage(userId: store.state.sessionUserState.sessionUser.userId),
  ];
  int _index;
  double _height;

  @override
  void initState() {
    _index = 0;
    _height =
        (drawerKey.currentContext.findRenderObject() as RenderBox).size.height;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        initialIndex: _index,
        length: 2,
        child: Container(
          height: _height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TabBar(
                tabs: [
                  Tab(text: '封鎖名單'),
                  Tab(text: '最近動態'),
                ],
                //indicatorSize: TabBarIndicatorSize.label,
                onTap: (value) {
                  setState(() {
                    _index = value;
                  });
                },
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _pages[_index],
              )
            ],
          ),
        ),
      );
}
