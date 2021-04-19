import 'package:hkgalden_flutter/models/tag.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

List<Channel> channelFromJson(List<dynamic> json) => json
    .map((thread) => Channel.fromJson(thread as Map<String, dynamic>))
    .toList();

@immutable
class Channel extends Equatable {
  final String channelId;
  final String channelName;
  final Color channelColor;
  final List<Tag> tags;

  const Channel(
      {required this.channelId,
      required this.channelName,
      required this.channelColor,
      required this.tags});

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        channelId: json['id'] as String,
        channelName: json['name'] as String,
        channelColor:
            Color(int.parse('FF${json['tags'][0]['color']}', radix: 16)),
        tags: (json['tags'] as List<dynamic>)
            .map((tag) => Tag.fromJson(tag as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object> get props => [channelId, channelName, channelColor, tags];
}
