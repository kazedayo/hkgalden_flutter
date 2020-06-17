import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

@immutable
class Channel extends Equatable {
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

  List<Object> get props => [channelId, channelName, channelColor];
}