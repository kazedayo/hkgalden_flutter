import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_action.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:redux/redux.dart';

class ChannelMiddleware extends MiddlewareClass<AppState> {
  @override
  Future<void> call(
      Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestChannelAction) {
      final List<Channel> channels = await HKGaldenApi().getChannelsQuery();
      channels == null
          ? next(RequestChannelErrorAction())
          : next(UpdateChannelAction(channels: channels));
    } else if (action is RequestChannelErrorAction) {
      next(RequestChannelAction());
    }
  }
}
