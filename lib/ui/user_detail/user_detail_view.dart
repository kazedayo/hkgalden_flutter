import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_action.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail/user_thread_list_view_model.dart';

class UserDetailView extends StatefulWidget {
  final User user;
  final Function onLogout;

  const UserDetailView({Key key, this.user, this.onLogout}) : super(key: key);

  @override
  _UserDetailViewState createState() => _UserDetailViewState();
}

class _UserDetailViewState extends State<UserDetailView> {
  bool _blockedButtonPressed;

  @override
  void initState() {
    _blockedButtonPressed = false;
    super.initState();
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
                                    width: 30, height: 30, color: Colors.grey)
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
                    FlatButton.icon(
                        onPressed: _blockedButtonPressed
                            ? null
                            : () {
                                setState(() {
                                  _blockedButtonPressed =
                                      !_blockedButtonPressed;
                                });
                                HKGaldenApi()
                                    .blockUser(widget.user.userId)
                                    .then((isSuccess) {
                                  setState(() {
                                    _blockedButtonPressed =
                                        !_blockedButtonPressed;
                                  });
                                  if (isSuccess) {
                                    Navigator.of(context).pop();
                                    store.dispatch(AppendUserToBlockListAction(
                                        widget.user.userId));
                                    scaffoldKey.currentState.showSnackBar(SnackBar(
                                        content: Text(
                                            '已封鎖會員 ${widget.user.nickName}')));
                                  } else {}
                                });
                              },
                        icon: Icon(Icons.block),
                        label: Text('封鎖')),
                  ],
                ),
                SizedBox(height: 15),
                Expanded(
                  child: _UserThreadListPage(userId: widget.user.userId),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 24,
        ),
      );
}

// class _BlockListPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) =>
//       StoreConnector<AppState, BlockedUsersViewModel>(
//         onInit: (store) => store.dispatch(RequestBlockedUsersAction()),
//         converter: (store) => BlockedUsersViewModel.create(store),
//         builder: (context, viewModel) => viewModel.isLoading
//             ? BlockedUsersLoadingSkeleton()
//             : GridView.builder(
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     mainAxisSpacing: 4,
//                     crossAxisSpacing: 4,
//                     childAspectRatio: 3),
//                 itemCount: viewModel.blockedUsers.length,
//                 itemBuilder: (context, index) {
//                   return BlockedUserCell(user: viewModel.blockedUsers[index]);
//                 }),
//       );
// }

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
                itemBuilder: (context, index) => Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            viewModel.userThreads[index].title,
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: viewModel.userThreads[index].tagColor),
                            child: Text(
                              '#${viewModel.userThreads[index].tagName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .caption
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                              strutStyle: StrutStyle(height: 1.25),
                            ),
                          ),
                        ),
                        Divider(indent: 8, height: 1, thickness: 1),
                      ],
                    )),
      );
}
