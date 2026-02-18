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
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180, childAspectRatio: 2.5),
      itemBuilder: (context, index) => ChannelCell(
        channel: state.channels[index],
      ),
      itemCount: state.channels.length,
    );
  }
}
