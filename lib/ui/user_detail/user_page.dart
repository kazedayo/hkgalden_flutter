import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/viewmodels/session_user_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, SessionUserPageViewModel>(
        converter: (store) => SessionUserPageViewModel.create(store),
        builder: (context, viewModel) => Scaffold(
          appBar: AppBar(),
          body: Stack(
            children: [
              Card(
                clipBehavior: Clip.hardEdge,
                color: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
                elevation: 6,
                margin: EdgeInsets.only(top: 40),
                child: Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: UserThreadListPage(
                    userId: viewModel.sessionUser.userId,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AvatarWidget(
                      avatarImage: viewModel.sessionUserAvatar,
                      userGroup: viewModel.sessionUserGroup,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viewModel.sessionUserName,
                          style: Theme.of(context).textTheme.bodyText1.copyWith(
                              color: viewModel.sessionUserGender == 'M'
                                  ? Theme.of(context).colorScheme.brotherColor
                                  : Theme.of(context).colorScheme.sisterColor,
                              shadows: [Shadow(offset: Offset(1, 1))]),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          viewModel.sessionUser.userId,
                          style: Theme.of(context).textTheme.caption.copyWith(
                              shadows: [Shadow(offset: Offset(1, 1))]),
                        ),
                        SizedBox(
                          height: 13,
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
