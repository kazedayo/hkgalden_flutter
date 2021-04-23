import 'package:backdrop/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/models/channel.dart';

class ChannelCell extends StatelessWidget {
  final Channel channel;

  const ChannelCell({Key? key, required this.channel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThreadListBloc threadListBloc =
        BlocProvider.of<ThreadListBloc>(context);
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, state) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          clipBehavior: Clip.hardEdge,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation:
              (state as ChannelLoaded).selectedChannelId == channel.channelId
                  ? 6
                  : 0,
          color: state.selectedChannelId == channel.channelId
              ? Theme.of(context).primaryColor
              : Theme.of(context).scaffoldBackgroundColor,
          child: TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: state.selectedChannelId == channel.channelId
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    BlocProvider.of<ChannelBloc>(context).add(
                        SetSelectedChannelEvent(channelId: channel.channelId));
                    threadListBloc.add(
                      RequestThreadListEvent(
                          channelId: channel.channelId,
                          page: 1,
                          isRefresh: false),
                    );
                    //Navigator.pop(context);
                    Backdrop.of(context).concealBackLayer();
                  },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    channel.channelName,
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(),
                  ),
                  const Spacer(flex: 3),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: channel.channelColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
