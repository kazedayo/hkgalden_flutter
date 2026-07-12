import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class ChannelRepository {
  ChannelRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;

  Future<List<Channel>?> getChannels() => _api.getChannelsQuery();
}
