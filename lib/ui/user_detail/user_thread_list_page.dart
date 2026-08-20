import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/user_thread_list/user_thread_list_bloc.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

class UserThreadListPage extends StatelessWidget {
  final String userId;

  const UserThreadListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserThreadListBloc>(
        create: (context) {
          final UserThreadListBloc userThreadListBloc = UserThreadListBloc(
              api: RepositoryProvider.of<HKGaldenApi>(context));
          userThreadListBloc
              .add(RequestUserThreadListEvent(userId: userId, page: 1));
          return userThreadListBloc;
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height / 2),
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
                      onTap: () =>
                          _openUserThread(loaded.userThreadList[index]),
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
                    const Divider(height: 1, thickness: 1, indent: 8),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }
}

/// Closes the user sheet, then pushes `/Thread`.
/// Tapping the thread already on screen only dismisses the sheet.
void _openUserThread(Thread thread) {
  final nav = navigatorKey.currentState;
  if (nav == null) {
    return;
  }

  var alreadyViewing = false;
  nav.popUntil((route) {
    if (route.settings.name == '/Thread') {
      final args = route.settings.arguments;
      if (args is ThreadPageArguments && args.threadId == thread.threadId) {
        alreadyViewing = true;
      }
      return true;
    }
    return route.isFirst;
  });

  if (alreadyViewing) {
    return;
  }

  nav.pushNamed('/Thread', arguments: ThreadPageArguments.fromThread(thread));
}
