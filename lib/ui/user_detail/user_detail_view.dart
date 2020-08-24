import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:octo_image/octo_image.dart';

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
                                : OctoImage(
                                    placeholderBuilder: (context) =>
                                        SizedBox.fromSize(
                                      size: Size.square(30),
                                    ),
                                    image:
                                        Image.network(widget.user.avatar).image,
                                    width: 30,
                                    height: 30,
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
                        onPressed: _blockedButtonPressed ||
                                StoreProvider.of<AppState>(context)
                                        .state
                                        .sessionUserState
                                        .isLoggedIn ==
                                    false
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
                                    StoreProvider.of<AppState>(context)
                                        .dispatch(AppendUserToBlockListAction(
                                            widget.user.userId));
                                    Navigator.of(context).pop();
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
                  child: UserThreadListPage(userId: widget.user.userId),
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
