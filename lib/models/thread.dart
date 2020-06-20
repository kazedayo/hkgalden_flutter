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

  Thread copyWith({
    int threadId,
    String title,
    List<Reply> replies,
    int totalReplies,
    String tagName,
    String tagColor,
  }) {
    return Thread(
      threadId: threadId ?? this.threadId,
      title: title ?? this.title,
      replies: replies ?? this.replies,
      totalReplies: totalReplies ?? this.totalReplies,
      tagName: tagName ?? this.tagName,
      tagColor: tagColor ?? this.tagColor,
    );
  }

  List<Object> get props => [threadId, title, replies, totalReplies, tagName, tagColor];
}