import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

@immutable
class Reply extends Equatable {
  final String replyId;
  final int floor;
  final String content;
  final User author;
  final String authorNickname;
  final DateTime date;
  final Reply parent;

  Reply(
      {this.replyId,
      this.floor,
      this.content,
      this.author,
      this.authorNickname,
      this.date,
      this.parent});

  factory Reply.fromJson(json) => new Reply(
        replyId: json['id'],
        floor: json['floor'],
        content: json['content'] == null
            ? null
            : HKGaldenHtmlParser().parse(
                String.fromCharCodes((json['content'] as String).codeUnits)),
        author: User.fromJson(json['author']),
        authorNickname:
            String.fromCharCodes((json['authorNickname'] as String).codeUnits),
        date: DateTime.parse(json['date']),
        parent: json['parent'] == null ? null : Reply.fromJson(json['parent']),
      );

  List<Object> get props =>
      [replyId, floor, content, author, authorNickname, date, parent];
}
