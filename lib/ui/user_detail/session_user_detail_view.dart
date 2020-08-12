import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/user_detail/block_list_page.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/utils/keys.dart';

class SessionUserDetailView extends StatefulWidget {
  @override
  _SessionUserDetailViewState createState() => _SessionUserDetailViewState();
}

class _SessionUserDetailViewState extends State<SessionUserDetailView> {
  int _index;
  double _height;
  final tabs = <int, Widget>{0: Text('最近動態'), 1: Text('封鎖名單')};

  @override
  void initState() {
    _index = 0;
    _height =
        (drawerKey.currentContext.findRenderObject() as RenderBox).size.height;
    super.initState();
  }

  void _onValueChanged(int value) {
    setState(() {
      _index = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      UserThreadListPage(
          userId: StoreProvider.of<AppState>(context)
              .state
              .sessionUserState
              .sessionUser
              .userId),
      BlockListPage(),
    ];
    return DefaultTabController(
      initialIndex: _index,
      length: 2,
      child: Container(
        height: _height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: CupertinoSlidingSegmentedControl(
                children: tabs,
                onValueChanged: _onValueChanged,
                groupValue: _index,
              ),
            ),
            SizedBox(
              height: 20,
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
}
