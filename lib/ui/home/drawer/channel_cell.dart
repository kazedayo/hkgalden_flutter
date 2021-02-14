import 'package:backdrop/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/viewmodels/home/drawer/home_drawer_view_model.dart';

class ChannelCell extends StatelessWidget {
  final HomeDrawerViewModel viewModel;
  final Channel channel;

  const ChannelCell({Key key, this.viewModel, this.channel}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Material(
            clipBehavior: Clip.hardEdge,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: viewModel.selectedChannelId == channel.channelId ? 6 : 0,
            color: viewModel.selectedChannelId == channel.channelId
                ? Theme.of(context).primaryColor
                : Theme.of(context).scaffoldBackgroundColor,
            child: FlatButton(
              disabledTextColor: Colors.white,
              onPressed: viewModel.selectedChannelId == channel.channelId
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      viewModel.onTap(channel.channelId);
                      //Navigator.pop(context);
                      Backdrop.of(context).concealBackLayer();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      channel.channelName,
                      style: Theme.of(context).textTheme.subtitle2.copyWith(),
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
                    const Spacer()
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
