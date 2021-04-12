import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/models/tag.dart';
import 'package:hkgalden_flutter/repository/channel_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:test/test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'channel_bloc_test.mocks.dart';

@GenerateMocks([ChannelRepository])
void main() {
  group('ChannelBloc', () {
    late ChannelRepository repository;
    late ChannelBloc channelBloc;

    setUp(() {
      repository = MockChannelRepository();
      channelBloc = ChannelBloc(repository: repository);
    });

    test('initial state should be ChannelLoading', () {
      expect(channelBloc.state, ChannelLoading());
    });

    blocTest('emits ChannelLoaded state when RequestChannelEvent added',
        build: () {
          when(repository.getChannels()).thenAnswer((_) async => [
                const Channel(
                    channelId: "channelId",
                    channelName: "channelName",
                    channelColor: Colors.black,
                    tags: [Tag(name: "name", color: Colors.black)])
              ]);
          return channelBloc;
        },
        act: (ChannelBloc bloc) => bloc.add(RequestChannelsEvent()),
        expect: () => [isA<ChannelLoaded>()],
        verify: (_) => verify(repository.getChannels()).called(1));

    blocTest(
        'state should remain unchanged when SetSelectedChannelEvent call on state ChannelLoading',
        build: () => channelBloc,
        act: (ChannelBloc bloc) =>
            bloc.add(const SetSelectedChannelEvent(channelId: 'bw')),
        expect: () => []);
  });
}
