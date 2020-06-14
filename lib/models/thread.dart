import 'package:meta/meta.dart';

@immutable
class Thread {
  final int threadId;
  final String title;
  final String authorName;
  final Duration lastReply;
  final int totalReplies;
  final String tagName;
  final String tagColor;

  Thread({
    this.threadId,
    this.title,
    this.authorName,
    this.lastReply,
    this.totalReplies,
    this.tagName,
    this.tagColor
  });

  factory Thread.fromJson(Map<String, dynamic> json) => new Thread(
    threadId: json['id'],
    title: json['title'],
    authorName: json['replies'][0]['authorNickname'],
    lastReply: DateTime.parse(json['replies'][0]['date']).difference(DateTime.now()),
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
        authorName == other.authorName && 
        lastReply == other.lastReply && 
        totalReplies == other.totalReplies && 
        tagName == other.tagName && 
        tagColor == other.tagColor;
  
  @override
  int get hashCode => 
    threadId.hashCode ^ 
    title.hashCode ^ 
    authorName.hashCode ^ 
    lastReply.hashCode ^ 
    totalReplies.hashCode ^ 
    tagName.hashCode ^ 
    tagColor.hashCode;
}