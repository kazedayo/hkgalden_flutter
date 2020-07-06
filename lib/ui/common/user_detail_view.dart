import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail_view_model.dart';

class UserDetailView extends StatelessWidget {
  final Function onLogout;

  const UserDetailView({Key key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        heightFactor: 0.25,
        widthFactor: 0.75,
        child: StoreConnector<AppState, UserDetailViewModel>(
          converter: (store) => UserDetailViewModel.create(store),
          builder: (context, viewModel) => Material(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Spacer(),
                AvatarWidget(
                    avatarImage: viewModel.userAvatar,
                    userGroup: viewModel.userGroup),
                SizedBox(height: 10),
                Text(viewModel.userName,
                    style: Theme.of(context).textTheme.bodyText1.copyWith(
                        color: viewModel.userGender == 'M'
                            ? Color(0xff22c1fe)
                            : Color(0xffff7aab))),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.settings), onPressed: () => null),
                    IconButton(
                        icon: Icon(Icons.exit_to_app),
                        onPressed: () {
                          Navigator.pop(context);
                          onLogout();
                        },
                        color: Colors.redAccent[400]),
                  ],
                ),
                Spacer(),
              ],
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5))),
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 6,
          ),
        ),
      );
}
