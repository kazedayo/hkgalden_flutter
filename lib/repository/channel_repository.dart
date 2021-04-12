import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class ChannelRepository {
  final _api = HKGaldenApi();

  Future<List<Channel>?> getChannels() => _api.getChannelsQuery();
}
