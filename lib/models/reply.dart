import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

Reply replyFromJson(dynamic json) =>
    Reply.fromJson(json, <String, String>{});

@immutable
class Reply extends Equatable {
  final String? replyId;
  final int floor;
  final String? content;
  final User author;
  final String authorNickname;
  final DateTime date;
  final Reply? parent;

  const Reply(
      {this.replyId,
      required this.floor,
      this.content,
      required this.author,
      required this.authorNickname,
      required this.date,
      this.parent});

  factory Reply.fromJson(dynamic json, [Map<String, String>? intern]) {
    intern ??= <String, String>{};
    final String? replyId = json['id'] as String?;
    final String? rawContent = json['content'] as String?;
    String? content;
    if (rawContent != null) {
      final String? interned = replyId == null ? null : intern[replyId];
      if (interned != null) {
        content = interned;
      } else {
        content = HKGaldenHtmlParser().parse(rawContent);
        if (replyId != null && content != null) {
          intern[replyId] = content;
        }
      }
    }
    return Reply(
      replyId: replyId,
      floor: json['floor'] as int,
      content: content,
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      authorNickname: json['authorNickname'] as String,
      date: DateTime.parse(json['date'] as String),
      parent: json['parent'] == null
          ? null
          : Reply.fromJson(json['parent'], intern),
    );
  }

  @override
  List<Object?> get props =>
      [replyId, floor, content, author, authorNickname, date, parent];
}
