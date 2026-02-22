import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/ui/home/drawer/channel_cell.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ChannelLoaded state =
        BlocProvider.of<ChannelBloc>(context).state as ChannelLoaded;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          alignment: WrapAlignment.start,
          children: state.channels
              .map(
                (channel) => SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 32) / 3,
                  child: ChannelCell(channel: channel),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
