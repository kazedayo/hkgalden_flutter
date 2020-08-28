import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/utils/keys.dart';

class AvatarWidget extends StatefulWidget {
  final Widget avatarImage;
  final User user;
  final List<UserGroup> userGroup;

  const AvatarWidget(
      {Key key,
      @required this.avatarImage,
      @required this.userGroup,
      this.user})
      : super(key: key);

  @override
  _AvatarWidgetState createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  bool _blockedButtonPressed;

  @override
  void initState() {
    _blockedButtonPressed = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton(
        enabled: widget.user == null ? false : true,
        offset: Offset(0, 60),
        itemBuilder: (context) => [
          PopupMenuItem(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.block,
                  color: _blockedButtonPressed ||
                          StoreProvider.of<AppState>(context)
                                  .state
                                  .sessionUserState
                                  .isLoggedIn ==
                              false
                      ? Colors.grey
                      : Colors.redAccent,
                ),
                onPressed: _blockedButtonPressed ||
                        StoreProvider.of<AppState>(context)
                                .state
                                .sessionUserState
                                .isLoggedIn ==
                            false
                    ? null
                    : () {
                        setState(() {
                          _blockedButtonPressed = !_blockedButtonPressed;
                        });
                        HKGaldenApi()
                            .blockUser(widget.user.userId)
                            .then((isSuccess) {
                          setState(() {
                            _blockedButtonPressed = !_blockedButtonPressed;
                          });
                          if (isSuccess) {
                            StoreProvider.of<AppState>(context).dispatch(
                                AppendUserToBlockListAction(
                                    widget.user.userId));
                            Navigator.of(context).pop();
                            scaffoldKey.currentState.showSnackBar(SnackBar(
                                content:
                                    Text('已封鎖會員 ${widget.user.nickName}')));
                          } else {}
                        });
                      },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.account_box,
                  color: Colors.black87,
                ),
                onPressed: null,
              )
            ],
          )),
        ],
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 5, 10),
          child: Material(
            shape: CircleBorder(),
            elevation: 6,
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 22,
                child: widget.avatarImage,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
                gradient: widget.userGroup.isEmpty
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.userGroup.first.groupId == 'ADMIN'
                              ? Color(0xff7435a0)
                              : Color(0xffe0561d),
                          widget.userGroup.first.groupId == 'ADMIN'
                              ? Color(0xff4a72d3)
                              : Color(0xffd8529a)
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
}
