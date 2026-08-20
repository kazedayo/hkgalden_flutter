import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

class _FakeApi extends Fake implements HKGaldenApi {
  int getChannelsCalls = 0;

  @override
  Future<List<Channel>?> getChannelsQuery() async {
    getChannelsCalls++;
    return [];
  }
}

void main() {
  group('ChannelBloc', () {
    late _FakeApi api;
    late ChannelBloc channelBloc;

    setUp(() {
      api = _FakeApi();
      channelBloc = ChannelBloc(api: api);
    });

    test('initial state should be ChannelLoading', () {
      expect(channelBloc.state, ChannelLoading());
    });

    blocTest('emits ChannelLoaded state when RequestChannelEvent added',
        build: () => channelBloc,
        act: (ChannelBloc bloc) => bloc.add(RequestChannelsEvent()),
        expect: () => [isA<ChannelLoaded>()],
        verify: (_) => expect(api.getChannelsCalls, 1));

    blocTest(
        'state should remain unchanged when SetSelectedChannelEvent add on state ChannelLoading',
        build: () => channelBloc,
        act: (ChannelBloc bloc) =>
            bloc.add(const SetSelectedChannelEvent(channelId: 'bw')),
        expect: () => []);

    blocTest('emits new state when SetSelectedChannelEvent added',
        build: () => channelBloc,
        act: (ChannelBloc bloc) => bloc
          ..add(RequestChannelsEvent())
          ..add(const SetSelectedChannelEvent(channelId: 'et')),
        expect: () => [
              const ChannelLoaded(channels: [], selectedChannelId: 'bw'),
              const ChannelLoaded(channels: [], selectedChannelId: 'et')
            ]);
  });
}
