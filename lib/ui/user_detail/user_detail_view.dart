import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/enums/user_profile.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_action.dart';
import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_action.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/common/blocked_user_cell.dart';
import 'package:hkgalden_flutter/ui/user_detail/blocked_users_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_loading_skeleton.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail/blocked_users_view_model.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail/user_thread_list_view_model.dart';

class UserDetailView extends StatefulWidget {
  final UserProfile profileType;
  final User user;
  final Function onLogout;

  const UserDetailView({Key key, this.profileType, this.user, this.onLogout})
      : super(key: key);

  @override
  _UserDetailViewState createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView>
    with SingleTickerProviderStateMixin {
  TabController _controller;
  int _selectedTab;
  List<Widget> _pages;

  @override
  void initState() {
    _controller = TabController(
        length: widget.profileType == UserProfile.sessionUser ? 2 : 1,
        vsync: this);
    _selectedTab = 0;
    _pages = <Widget>[
      if (widget.profileType == UserProfile.sessionUser) _BlockListPage(),
      _UserThreadListPage(userId: widget.user.userId),
    ];
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
        child: Material(
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 10),
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
                            avatarImage: widget.user.avatar == ''
                                ? SvgPicture.asset('assets/icon-hkgalden.svg',
                                    width: 30, height: 30)
                                : CachedNetworkImage(
                                    imageUrl: widget.user.avatar,
                                    width: 30,
                                    height: 30,
                                    fadeInDuration: Duration(milliseconds: 250),
                                    fadeOutDuration:
                                        Duration(milliseconds: 250),
                                  ),
                            userGroup: widget.user.userGroup),
                        SizedBox(width: 10),
                        Text(widget.user.nickName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(
                                    color: widget.user.gender == 'M'
                                        ? Theme.of(context)
                                            .colorScheme
                                            .brotherColor
                                        : Theme.of(context)
                                            .colorScheme
                                            .sisterColor)),
                      ],
                    ),
                    Visibility(
                      visible: widget.profileType == UserProfile.sessionUser,
                      child: Row(
                        children: <Widget>[
                          IconButton(
                              icon: Icon(Icons.settings), onPressed: null),
                          IconButton(
                              icon: Icon(Icons.exit_to_app),
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onLogout();
                              },
                              color: Colors.redAccent[400]),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                TabBar(
                  controller: _controller,
                  tabs: <Widget>[
                    if (widget.profileType == UserProfile.sessionUser)
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
                    child: PageTransitionSwitcher(
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) =>
                      FadeThroughTransition(
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          animation: animation,
                          secondaryAnimation: secondaryAnimation,
                          child: child),
                  child: _pages[_selectedTab],
                )),
              ],
            ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 6,
        ),
      );
}

class _BlockListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, BlockedUsersViewModel>(
        onInit: (store) => store.dispatch(RequestBlockedUsersAction()),
        converter: (store) => BlockedUsersViewModel.create(store),
        builder: (context, viewModel) => viewModel.isLoading
            ? BlockedUsersLoadingSkeleton()
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 3),
                itemCount: viewModel.blockedUsers.length,
                itemBuilder: (context, index) {
                  return BlockedUserCell(user: viewModel.blockedUsers[index]);
                }),
      );
}

class _UserThreadListPage extends StatelessWidget {
  final String userId;

  _UserThreadListPage({this.userId});

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, UserThreadListViewModel>(
        onInit: (store) => store
            .dispatch(RequestUserThreadListAction(userId: userId, page: 1)),
        converter: (store) => UserThreadListViewModel.create(store),
        builder: (context, viewModel) => viewModel.isLoading
            ? UserThreadListLoadingSkeleton()
            : ListView.builder(
                itemCount: viewModel.userThreads.length,
                itemBuilder: (context, index) => ListTile(
                      title: Text(viewModel.userThreads[index].title),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: viewModel.userThreads[index].tagColor),
                        child: Text(
                          '#${viewModel.userThreads[index].tagName}',
                          strutStyle: StrutStyle(height: 1.25),
                        ),
                      ),
                    )),
      );
}
