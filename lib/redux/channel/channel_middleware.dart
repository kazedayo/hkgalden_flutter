import 'dart:async';

import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_action.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:redux/redux.dart';

class ChannelMiddleware extends MiddlewareClass<AppState> {
  @override
  void call(Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestChannelAction) {
      List<Channel> channels = await _getChannelsQuery(next);
      next(UpdateChannelAction(channels: channels));
    } else if (action is RequestChannelErrorAction) {
      next(RequestChannelAction());
    }
  }

  Future<List<Channel>> _getChannelsQuery(NextDispatcher next) async {
    final client = HKGaldenApi().client;

    const String query = r'''
      query GetChannels {
        channels {
          id
          name
          tags {
            name
            color
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      documentNode: gql(query),
    );

    final QueryResult queryResult = await client.query(options);

    if (queryResult.hasException) {
      next(RequestChannelErrorAction());
    }

    final List<dynamic> result = queryResult.data['channels'] as List<dynamic>;

    final List<Channel> threads = result.map((thread) => Channel.fromJson(thread)).toList();

    return threads;
  }
}