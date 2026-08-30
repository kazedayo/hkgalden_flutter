import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

List<User> userListFromJson(List<dynamic> json) =>
    json.map((user) => User.fromJson(user as Map<String, dynamic>)).toList();

User userFromJson(Map<String, dynamic> json) => User.fromJson(json);

@immutable
class User extends Equatable {
  final String userId;
  final String nickName;
  final String avatar;
  final String? groupId;
  final String? gender;
  final List<String> blockedUsers;

  const User({
    required this.userId,
    required this.nickName,
    required this.avatar,
    this.groupId,
    this.gender,
    required this.blockedUsers,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['id'] as String,
        nickName: json['nickname'] as String,
        avatar: json['avatar'] == null ? '' : json['avatar'] as String,
        groupId: json['groups'] is List && (json['groups'] as List).isNotEmpty
            ? (json['groups'] as List).first['id'] as String?
            : null,
        gender: json['gender'] as String?,
        blockedUsers: json['blockedUserIds'] == null
            ? []
            : (json['blockedUserIds'] as List<dynamic>)
                .map((id) => id.toString())
                .toList(),
      );

  User copyWith({
    String? userId,
    String? nickName,
    String? avatar,
    String? groupId,
    String? gender,
    List<String>? blockedUsers,
  }) =>
      User(
          userId: userId ?? this.userId,
          nickName: nickName ?? this.nickName,
          avatar: avatar ?? this.avatar,
          groupId: groupId ?? this.groupId,
          gender: gender ?? this.gender,
          blockedUsers: blockedUsers ?? this.blockedUsers);

  @override
  List<Object?> get props =>
      [userId, nickName, avatar, groupId, gender, blockedUsers];
}
