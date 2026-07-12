import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/user_thread_list/user_thread_list_bloc.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/repository/user_thread_list_repository.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
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
      create: (context) => UserThreadListRepository(
          api: RepositoryProvider.of<HKGaldenApi>(context)),
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
            builder: (context, state) {
              if (state is UserThreadListLoading) {
                return UserThreadListLoadingSkeleton();
              }
              if (state is UserThreadListError) {
                return ErrorPage(
                  message: '無法載入主題列表',
                  onRetry: () => BlocProvider.of<UserThreadListBloc>(context)
                      .add(RequestUserThreadListEvent(userId: userId, page: 1)),
                );
              }
              final loaded = state as UserThreadListLoaded;
              return ListView.builder(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom),
                itemCount: loaded.userThreadList.length,
                findChildIndexCallback: (Key key) {
                  if (key is ValueKey<int>) {
                    return loaded.userThreadList
                        .indexWhere((thread) => thread.threadId == key.value);
                  }
                  return null;
                },
                itemBuilder: (context, index) => Column(
                  key: ValueKey(loaded.userThreadList[index].threadId),
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        loaded.userThreadList[index].title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: ThreadTagChip(
                        label: loaded.userThreadList[index].tagName,
                        backgroundColor:
                            loaded.userThreadList[index].tagColor,
                      ),
                    ),
                    const ListDivider(indent: 8),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
