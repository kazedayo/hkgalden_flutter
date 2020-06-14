import 'package:hkgalden_flutter/models/thread_reply.dart';
import 'package:meta/meta.dart';

@immutable
class Thread {
  final int threadId;
  final String title;
  final List<ThreadReply> replies;
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
    replies: (json['replies'] as List<dynamic>).map((reply) => ThreadReply.fromJson(reply)).toList(),
    totalReplies: json['totalReplies'],
    tagName: json['tags'][0]['name'],
    tagColor: json['tags'][0]['color'],
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is Thread && 
        runtimeType == other.runtimeType && 
        threadId == other.threadId && 
        title == other.title && 
        replies == other.replies &&
        totalReplies == other.totalReplies && 
        tagName == other.tagName && 
        tagColor == other.tagColor;
  
  @override
  int get hashCode => 
    threadId.hashCode ^ 
    title.hashCode ^ 
    replies.hashCode ^ 
    totalReplies.hashCode ^ 
    tagName.hashCode ^ 
    tagColor.hashCode;
}