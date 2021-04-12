import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/blocked_users/blocked_users_bloc.dart';
import 'package:hkgalden_flutter/repository/blocked_users_repository.dart';
import 'package:hkgalden_flutter/ui/common/blocked_user_cell.dart';
import 'package:hkgalden_flutter/ui/user_detail/blocked_users_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';

class BlockListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<BlockedUsersRepository>(
      create: (context) => BlockedUsersRepository(),
      child: BlocProvider<BlockedUsersBloc>(
        create: (context) {
          final BlockedUsersBloc blockedUsersBloc = BlockedUsersBloc(
              repository:
                  RepositoryProvider.of<BlockedUsersRepository>(context));
          blockedUsersBloc.add(RequestBlockedUsersEvent());
          return blockedUsersBloc;
        },
        child: BlocBuilder<BlockedUsersBloc, BlockedUsersState>(
          builder: (context, state) => Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).primaryColor,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            elevation: 6,
            child: SizedBox(
              height: displayHeight(context) / 2,
              child: state is BlockedUsersLoading
                  ? BlockedUsersLoadingSkeleton()
                  : ListView.builder(
                      padding: EdgeInsets.only(
                          top: 6,
                          left: 12,
                          right: 12,
                          bottom: MediaQuery.of(context).padding.bottom),
                      itemCount:
                          (state as BlockedUsersLoaded).blockedUsers.length,
                      itemBuilder: (context, index) {
                        return BlockedUserCell(user: state.blockedUsers[index]);
                      }),
            ),
          ),
        ),
      ),
    );
  }
}
