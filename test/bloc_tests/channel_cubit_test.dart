import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_cubit.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements HKGaldenApi {
  int getChannelsCalls = 0;

  @override
  Future<List<Channel>?> getChannelsQuery() async {
    getChannelsCalls++;
    return [];
  }
}

void main() {
  group('ChannelCubit', () {
    late _FakeApi api;
    late ChannelCubit channelCubit;

    setUp(() {
      api = _FakeApi();
      channelCubit = ChannelCubit(api: api);
    });

    test('initial state should be ChannelLoading', () {
      expect(channelCubit.state, ChannelLoading());
    });

    blocTest('emits ChannelLoaded state when requestChannels is called',
        build: () => channelCubit,
        act: (ChannelCubit bloc) => bloc.requestChannels(),
        expect: () => [isA<ChannelLoaded>()],
        verify: (_) => expect(api.getChannelsCalls, 1));

    blocTest(
        'state should remain unchanged when setSelectedChannel called on ChannelLoading',
        build: () => channelCubit,
        act: (ChannelCubit bloc) => bloc.setSelectedChannel('bw'),
        expect: () => []);

    blocTest('emits new state when setSelectedChannel is called',
        build: () => channelCubit,
        act: (ChannelCubit bloc) async {
          await bloc.requestChannels();
          bloc.setSelectedChannel('et');
        },
        expect: () => [
              const ChannelLoaded(channels: [], selectedChannelId: 'bw'),
              const ChannelLoaded(channels: [], selectedChannelId: 'et')
            ]);
  });
}
