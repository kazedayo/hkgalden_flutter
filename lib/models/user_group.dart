import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

@immutable
class UserGroup extends Equatable {
  final String groupId;

  const UserGroup({required this.groupId});

  factory UserGroup.fromJson(Map<String, dynamic> json) => UserGroup(
        groupId: json['id'] as String,
      );

  @override
  List<Object> get props => [groupId];
}
