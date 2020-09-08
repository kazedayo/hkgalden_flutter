import 'package:auto_size_text/auto_size_text.dart';
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
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Material(
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AutoSizeText(
                    channel.channelName,
                    minFontSize: 10,
                    maxFontSize: 14,
                    maxLines: 1,
                  ),
                  Spacer(),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: channel.channelColor,
                      shape: BoxShape.circle,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
}
