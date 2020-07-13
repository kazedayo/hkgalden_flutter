import 'package:hkgalden_flutter/models/tag.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

@immutable
class Channel extends Equatable {
  final String channelId;
  final String channelName;
  final Color channelColor;
  final List<Tag> tags;

  Channel({this.channelId, this.channelName, this.channelColor, this.tags});

  factory Channel.fromJson(Map<String, dynamic> json) => new Channel(
        channelId: json['id'],
        channelName: json['name'],
        channelColor:
            Color(int.parse('FF' + json['tags'][0]['color'], radix: 16)),
        tags: (json['tags'] as List<dynamic>)
            .map((tag) => Tag.fromJson(tag))
            .toList(),
      );

  List<Object> get props => [channelId, channelName, channelColor, tags];
}
