import 'package:hkgalden_flutter/models/reply.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

@immutable
class Thread extends Equatable{
  final int threadId;
  final String title;
  final List<Reply> replies;
  final int totalReplies;
  final String tagName;
  final String tagColor;

  Thread({
    this.threadId,
    this.title,
    this.replies,
    this.totalReplies,
    this.tagName,
    this.tagColor
  });

  factory Thread.fromJson(Map<String, dynamic> json) => new Thread(
    threadId: json['id'],
    title: json['title'],
    replies: (json['replies'] as List<dynamic>).map((reply) => Reply.fromJson(reply)).toList(),
    totalReplies: json['totalReplies'],
    tagName: json['tags'][0]['name'],
    tagColor: json['tags'][0]['color'],
  );

  List<Object> get props => [threadId, title, replies, totalReplies, tagName, tagColor];
}