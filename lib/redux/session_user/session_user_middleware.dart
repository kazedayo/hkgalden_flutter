import 'dart:async';

import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/models/session_user.dart';
import 'package:redux/redux.dart';

class SessionUserMiddleware extends MiddlewareClass<AppState> {
  @override
  void call (Store<AppState> store, dynamic action, NextDispatcher next) async {
    if (action is RequestSessionUserAction) {
      next(action);
      SessionUser sessionUser = await _getSessionUserQuery();
      next(UpdateSessionUserAction(sessionUser: sessionUser));
    } else {
      next(action);
    }
  }

  Future<SessionUser> _getSessionUserQuery() async {
    final client = HKGaldenApi().client;

    const String query = r'''
      query GetSessionUser {
        sessionUser {
          id
          nickname
          avatar
          groups {
            name
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      documentNode: gql(query),
    );

    final QueryResult queryResult = await client.query(options);

    if (queryResult.hasException) {
      print(queryResult.exception.toString());
    }

    final dynamic result = queryResult.data['sessionUser'] as dynamic;

    final SessionUser sessionUser = SessionUser.fromJson(result);

    return sessionUser;
  }
}