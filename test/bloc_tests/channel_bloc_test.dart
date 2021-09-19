import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/repository/channel_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'channel_bloc_test.mocks.dart';

@GenerateMocks([ChannelRepository])
void main() {
  group('ChannelBloc', () {
    late ChannelRepository repository;
    late ChannelBloc channelBloc;

    setUp(() {
      repository = MockChannelRepository();
      when(repository.getChannels()).thenAnswer((_) async => []);
      channelBloc = ChannelBloc(repository: repository);
    });

    test('initial state should be ChannelLoading', () {
      expect(channelBloc.state, ChannelLoading());
    });

    blocTest('emits ChannelLoaded state when RequestChannelEvent added',
        build: () => channelBloc,
        act: (ChannelBloc bloc) => bloc.add(RequestChannelsEvent()),
        expect: () => [isA<ChannelLoaded>()],
        verify: (_) => verify(repository.getChannels()).called(1));

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
