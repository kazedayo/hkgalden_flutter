import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_action.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/viewmodels/user_detail/user_thread_list_view_model.dart';

class UserThreadListPage extends StatelessWidget {
  final String userId;

  UserThreadListPage({this.userId});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: displayHeight(context) / 2),
        child: StoreConnector<AppState, UserThreadListViewModel>(
          distinct: true,
          onInit: (store) => store
              .dispatch(RequestUserThreadListAction(userId: userId, page: 1)),
          converter: (store) => UserThreadListViewModel.create(store),
          builder: (context, viewModel) => viewModel.isLoading
              ? UserThreadListLoadingSkeleton()
              : ListView.builder(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom),
                  itemCount: viewModel.userThreads.length,
                  itemBuilder: (context, index) => Column(
                        children: <Widget>[
                          ListTile(
                              title: Text(
                                viewModel.userThreads[index].title,
                              ),
                              trailing: Chip(
                                label: Text(
                                  '#${viewModel.userThreads[index].tagName}',
                                  strutStyle: StrutStyle(height: 1.25),
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption
                                      .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700),
                                ),
                                backgroundColor:
                                    viewModel.userThreads[index].tagColor,
                              )),
                          Divider(indent: 8, height: 1, thickness: 1),
                        ],
                      )),
        ),
      );
}
