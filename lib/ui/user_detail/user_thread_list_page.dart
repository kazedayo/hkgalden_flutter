import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/user_thread_list/user_thread_list_bloc.dart';
import 'package:hkgalden_flutter/repository/user_thread_list_repository.dart';
import 'package:hkgalden_flutter/ui/common/list_divider.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';

class UserThreadListPage extends StatelessWidget {
  final String userId;

  const UserThreadListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<UserThreadListRepository>(
      create: (context) => UserThreadListRepository(),
      child: BlocProvider<UserThreadListBloc>(
        create: (context) {
          final UserThreadListBloc userThreadListBloc = UserThreadListBloc(
              repository:
                  RepositoryProvider.of<UserThreadListRepository>(context));
          userThreadListBloc
              .add(RequestUserThreadListEvent(userId: userId, page: 1));
          return userThreadListBloc;
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: displayHeight(context) / 2),
          child: BlocBuilder<UserThreadListBloc, UserThreadListState>(
            builder: (context, state) => state is UserThreadListLoading
                ? UserThreadListLoadingSkeleton()
                : ListView.builder(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom),
                    itemCount:
                        (state as UserThreadListLoaded).userThreadList.length,
                    itemBuilder: (context, index) => Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            state.userThreadList[index].title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: ThreadTagChip(
                            label: state.userThreadList[index].tagName,
                            backgroundColor:
                                state.userThreadList[index].tagColor,
                          ),
                        ),
                        const ListDivider(indent: 8),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
