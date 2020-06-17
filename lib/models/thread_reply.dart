import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

@immutable
class ThreadReply extends Equatable {
  final String authorNickname;
  final DateTime date;

  ThreadReply({
    this.authorNickname,
    this.date,
  });

  factory ThreadReply.fromJson(json) => new ThreadReply(
    authorNickname: json['authorNickname'],
    date: DateTime.parse(json['date']),
  );

 List<Object> get props => [authorNickname, date];
}