import 'package:hkgalden_flutter/models/channel.dart';

class RequestChannelAction {}

class UpdateChannelAction {
  final List<Channel> channels;

  UpdateChannelAction({
    this.channels
  });
}

class RequestChannelErrorAction {}

class SetSelectedChannelId {
  final String channelId;

  SetSelectedChannelId({
    this.channelId
  });
}