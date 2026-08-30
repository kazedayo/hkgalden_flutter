import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/reply.dart';

List<Thread> threadListFromJson(List<dynamic> json) => json
    .map((thread) => Thread.fromJson(thread as Map<String, dynamic>))
    .toList();

Thread threadFromJson(Map<String, dynamic> json) => Thread.fromJson(json);

@immutable
class Thread extends Equatable {
  final int threadId;
  final String title;
  final String status;
  final List<Reply> replies;
  final int totalReplies;
  final String tagName;
  final Color tagColor;

  const Thread(
      {required this.threadId,
      required this.title,
      required this.status,
      required this.replies,
      required this.totalReplies,
      required this.tagName,
      required this.tagColor});

  factory Thread.fromJson(Map<String, dynamic> json) {
    final intern = <String, String>{};
    return Thread(
      threadId: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      replies: (json['replies'] as List<dynamic>)
          .map((reply) => Reply.fromJson(reply, intern))
          .toList(),
      totalReplies: json['totalReplies'] as int,
      tagName: json['tags'][0]['name'] as String,
      tagColor: Color(int.parse('FF${json['tags'][0]['color']}', radix: 16)),
    );
  }

  Thread copyWith({List<Reply>? replies}) {
    return Thread(
      threadId: threadId,
      title: title,
      status: status,
      replies: replies ?? this.replies,
      totalReplies: totalReplies,
      tagName: tagName,
      tagColor: tagColor,
    );
  }

  /// Lowest floor (list cache may include a full page of replies).
  Reply get originalPost {
    assert(replies.isNotEmpty);
    return replies.reduce((a, b) => a.floor <= b.floor ? a : b);
  }

  /// Highest floor (do not assume index 1).
  Reply get latestReply {
    assert(replies.isNotEmpty);
    return replies.reduce((a, b) => a.floor >= b.floor ? a : b);
  }

  @override
  List<Object> get props =>
      [threadId, title, status, replies, totalReplies, tagName, tagColor];
}
