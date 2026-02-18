import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

UserGroup userGroupFromJson(Map<String, dynamic> json) =>
    UserGroup.fromJson(json);

@immutable
class UserGroup extends Equatable {
  final String groupId;
  final String groupName;

  const UserGroup({
    required this.groupId,
    required this.groupName,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) => UserGroup(
        groupId: json['id'] as String,
        groupName: json['name'] as String,
      );

  @override
  List<Object> get props => [groupId, groupName];
}
