import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

@immutable
class Tag extends Equatable {
  final String id;
  final String name;
  final Color color;

  Tag({this.id, this.name, this.color});

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
      id: json['id'],
      name: json['name'],
      color: Color(int.parse('FF' + json['color'], radix: 16)));

  List<Object> get props => [id, name, color];
}
