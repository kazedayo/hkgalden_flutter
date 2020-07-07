import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/common/blocked_user_cell.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail_view_model.dart';

class UserDetailView extends StatefulWidget {
  final Function onLogout;

  const UserDetailView({Key key, this.onLogout}) : super(key: key);

  @override
  _UserDetailViewState createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView>
    with SingleTickerProviderStateMixin {
  TabController _controller;
  int _selectedTab;

  @override
  void initState() {
    _controller = TabController(length: 2, vsync: this);
    _selectedTab = 0;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 0.75,
        child: StoreConnector<AppState, UserDetailViewModel>(
          converter: (store) => UserDetailViewModel.create(store),
          builder: (context, viewModel) => Material(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(width: 13),
                        AvatarWidget(
                            avatarImage: viewModel.userAvatar,
                            userGroup: viewModel.userGroup),
                        SizedBox(width: 10),
                        Text(viewModel.userName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(
                                    color: viewModel.userGender == 'M'
                                        ? Color(0xff22c1fe)
                                        : Color(0xffff7aab))),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        IconButton(icon: Icon(Icons.settings), onPressed: null),
                        IconButton(
                            icon: Icon(Icons.exit_to_app),
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onLogout();
                            },
                            color: Colors.redAccent[400]),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 15),
                TabBar(
                  controller: _controller,
                  tabs: <Widget>[
                    Tab(text: '封鎖名單'),
                    Tab(text: '最近動態'),
                  ],
                  onTap: (index) {
                    setState(() {
                      _selectedTab = index;
                    });
                  },
                ),
                Expanded(
                  child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          childAspectRatio: 3),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return BlockedUserCell(userName: 'user00$index');
                      }),
                ),
              ],
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 6,
          ),
        ),
      );
}
