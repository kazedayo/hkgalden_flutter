import 'dart:async';

import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:redux/redux.dart';

class SessionUserMiddleware extends MiddlewareClass<AppState> {
  @override
  void call(Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestSessionUserAction) {
      User sessionUser = await _getSessionUserQuery(next);
      sessionUser == null
          ? next(RequestSessionUserErrorAction())
          : next(UpdateSessionUserAction(sessionUser: sessionUser));
    } else if (action is RequestSessionUserErrorAction) {
      next(RequestSessionUserAction());
    }
  }

  Future<User> _getSessionUserQuery(NextDispatcher next) async {
    final client = HKGaldenApi().client;

    const String query = r'''
      query GetSessionUser {
        sessionUser {
          id
          nickname
          avatar
          gender
          groups {
            id
            name
          }
          blockedUserIds
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      documentNode: gql(query),
    );

    final QueryResult queryResult = await client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final dynamic result = queryResult.data['sessionUser'] as dynamic;

      final User sessionUser = User.fromJson(result);

      return sessionUser;
    }
  }
}
