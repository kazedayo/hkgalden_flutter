import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/tag.dart';

List<Channel> channelFromJson(List<dynamic> json) => json
    .map((thread) => Channel.fromJson(thread as Map<String, dynamic>))
    .toList();

@immutable
class Channel extends Equatable {
  final String channelId;
  final String channelName;
  final List<Tag> tags;

  const Channel(
      {required this.channelId,
      required this.channelName,
      required this.tags});

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        channelId: json['id'] as String,
        channelName: json['name'] as String,
        tags: (json['tags'] as List<dynamic>)
            .map((tag) => Tag.fromJson(tag as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object> get props => [channelId, channelName, tags];
}
