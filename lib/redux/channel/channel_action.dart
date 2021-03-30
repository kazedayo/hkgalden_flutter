import 'package:hkgalden_flutter/models/channel.dart';

class RequestChannelAction {}

class UpdateChannelAction {
  final List<Channel> channels;

  UpdateChannelAction({required this.channels});
}

class RequestChannelErrorAction {}

class SetSelectedChannelId {
  final String channelId;

  SetSelectedChannelId({required this.channelId});
}
