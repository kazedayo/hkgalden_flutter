import 'package:meta/meta.dart';

@immutable
class ThreadReply {
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

 @override
  bool operator ==(Object other) =>
    identical(this, other) ||
      other is ThreadReply && 
        runtimeType == other.runtimeType && 
        authorNickname == other.authorNickname && 
        date == other.date;
  
  @override
  int get hashCode => 
    authorNickname.hashCode ^ 
    date.hashCode;
}