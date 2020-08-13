import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_action.dart';
import 'package:hkgalden_flutter/ui/common/blocked_user_cell.dart';
import 'package:hkgalden_flutter/ui/user_detail/blocked_users_loading_skeleton.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail/blocked_users_view_model.dart';

class BlockListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, BlockedUsersViewModel>(
        onInit: (store) => store.dispatch(RequestBlockedUsersAction()),
        converter: (store) => BlockedUsersViewModel.create(store),
        builder: (context, viewModel) => viewModel.isLoading
            ? BlockedUsersLoadingSkeleton()
            : ListView.builder(
                itemCount: viewModel.blockedUsers.length,
                itemBuilder: (context, index) {
                  return BlockedUserCell(user: viewModel.blockedUsers[index]);
                }),
      );
}
