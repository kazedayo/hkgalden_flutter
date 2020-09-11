import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

@immutable
class Thread extends Equatable {
  final int threadId;
  final String title;
  final String status;
  final List<Reply> replies;
  final int totalReplies;
  final String tagName;
  final Color tagColor;

  Thread(
      {this.threadId,
      this.title,
      this.status,
      this.replies,
      this.totalReplies,
      this.tagName,
      this.tagColor});

  factory Thread.fromJson(Map<String, dynamic> json) => new Thread(
        threadId: json['id'],
        title: String.fromCharCodes((json['title'] as String).trim().runes),
        status: json['status'],
        replies: (json['replies'] as List<dynamic>)
            .map((reply) => Reply.fromJson(reply))
            .toList(),
        totalReplies: json['totalReplies'],
        tagName: json['tags'][0]['name'],
        tagColor: Color(int.parse('FF${json['tags'][0]['color']}', radix: 16)),
      );

  factory Thread.initial() => Thread(
        threadId: 0,
        title: '',
        status: '',
        replies: [],
        totalReplies: 0,
        tagName: '',
        tagColor: Colors.white,
      );

  Thread copyWith({
    int threadId,
    String title,
    String status,
    List<Reply> replies,
    int totalReplies,
    String tagName,
    Color tagColor,
  }) {
    return Thread(
      threadId: threadId ?? this.threadId,
      title: title ?? this.title,
      status: status ?? this.status,
      replies: replies ?? this.replies,
      totalReplies: totalReplies ?? this.totalReplies,
      tagName: tagName ?? this.tagName,
      tagColor: tagColor ?? this.tagColor,
    );
  }

  List<Object> get props =>
      [threadId, title, status, replies, totalReplies, tagName, tagColor];
}
