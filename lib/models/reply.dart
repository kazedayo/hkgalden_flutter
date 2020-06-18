import 'package:hkgalden_flutter/models/user.dart';
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

  Reply({
    this.replyId,
    this.floor,
    this.content,
    this.author,
    this.authorNickname,
    this.date,
  });

  factory Reply.fromJson(json) => new Reply(
    replyId: json['id'],
    floor: json['floor'],
    content: json['content'],
    author: User.fromJson(json['author']),
    authorNickname: json['authorNickname'],
    date: DateTime.parse(json['date']),
  );

 List<Object> get props => [replyId, floor, content, author, authorNickname, date];
}