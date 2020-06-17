import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:meta/meta.dart';

@immutable
class SessionUser extends Equatable {
  final String userId;
  final String nickName;
  final String avatar;
  final List<UserGroup> userGroup;

  SessionUser({
    this.userId,
    this.nickName,
    this.avatar,
    this.userGroup,
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
    userId: json['id'],
    nickName: json['nickname'],
    avatar: json['avatar'],
    userGroup: (json['groups'] as List<dynamic>).map((group) => UserGroup.fromJson(group)).toList(),
  );

  List<Object> get props => [userId, nickName, avatar, /*userGroup*/];
}