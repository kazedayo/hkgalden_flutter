import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_action.dart';
import 'package:hkgalden_flutter/ui/common/blocked_user_cell.dart';
import 'package:hkgalden_flutter/ui/user_detail/blocked_users_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail/blocked_users_view_model.dart';

class BlockListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, BlockedUsersViewModel>(
        onInit: (store) => store.dispatch(RequestBlockedUsersAction()),
        converter: (store) => BlockedUsersViewModel.create(store),
        builder: (context, viewModel) => Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.hardEdge,
          color: Theme.of(context).primaryColor,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10))),
          elevation: 6,
          child: SizedBox(
            height: displayHeight(context) / 2,
            child: viewModel.isLoading
                ? BlockedUsersLoadingSkeleton()
                : ListView.builder(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom),
                    itemCount: viewModel.blockedUsers.length,
                    itemBuilder: (context, index) {
                      return BlockedUserCell(
                          user: viewModel.blockedUsers[index]);
                    }),
          ),
        ),
      );
}
