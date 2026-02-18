import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

Reply replyFromJson(dynamic json) => Reply.fromJson(json);

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

  factory Reply.fromJson(dynamic json) => Reply(
        replyId: json['id'] as String?,
        floor: json['floor'] as int,
        content: json['content'] == null
            ? null
            : HKGaldenHtmlParser().parse(json['content'] as String),
        author: User.fromJson(json['author'] as Map<String, dynamic>),
        authorNickname: json['authorNickname'] as String,
        date: DateTime.parse(json['date'] as String),
        parent: json['parent'] == null ? null : Reply.fromJson(json['parent']),
      );

  @override
  List<Object?> get props =>
      [replyId, floor, content, author, authorNickname, date, parent];
}
