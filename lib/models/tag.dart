import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class Tag extends Equatable {
  final String? id;
  final String name;
  final Color color;

  const Tag({this.id, required this.name, required this.color});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
      id: json['id'] as String?,
      name: json['name'] as String,
      color: Color(int.parse('FF${json['color']}', radix: 16)));

  @override
  List<Object> get props => [name, color];
}
