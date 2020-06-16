import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

@immutable
class Channel {
  final String channelId;
  final String channelName;
  final Color channelColor;

  Channel({
    this.channelId,
    this.channelName,
    this.channelColor,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => new Channel(
    channelId: json['id'],
    channelName: json['name'],
    channelColor: Color(int.parse('FF'+json['tags'][0]['color'], radix: 16)),
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is Channel && 
        runtimeType == other.runtimeType && 
        channelId == other.channelId && 
        channelName == other.channelName && 
        channelColor == other.channelColor;
  
  @override
  int get hashCode => 
    channelId.hashCode ^ 
    channelName.hashCode ^ 
    channelColor.hashCode;
}