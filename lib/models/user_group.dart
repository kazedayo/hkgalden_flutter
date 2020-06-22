import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';

@immutable
class UserGroup extends Equatable {
  final String groupId;
  final String groupName;

  UserGroup({
    this.groupId,
    this.groupName,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) => UserGroup(
    groupId: json['id'],
    groupName: json['name'],
  );

  List<Object> get props => [groupId, groupName];
}