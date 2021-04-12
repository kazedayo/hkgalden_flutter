import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/user_thread_list/user_thread_list_bloc.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/repository/user_thread_list_repository.dart';

class UserThreadListPage extends StatelessWidget {
  final String userId;

  const UserThreadListPage({required this.userId});

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
                                ),
                                trailing: Chip(
                                  label: Text(
                                    '#${state.userThreadList[index].tagName}',
                                    strutStyle: const StrutStyle(height: 1.25),
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption!
                                        .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                  ),
                                  backgroundColor:
                                      state.userThreadList[index].tagColor,
                                )),
                            const Divider(indent: 8, height: 1, thickness: 1),
                          ],
                        )),
          ),
        ),
      ),
    );
  }
}
