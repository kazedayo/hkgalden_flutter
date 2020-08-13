import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/smiley.dart';

class SmileyPack extends Equatable {
  final String id;
  final String title;
  final List<Smiley> smilies;

  SmileyPack({
    this.id,
    this.title,
    this.smilies,
  });

  factory SmileyPack.fromJson(Map<String, dynamic> json) => SmileyPack(
      id: json['id'],
      title: json['title'],
      smilies: (json['smilies'] as List<dynamic>)
          .map((smiley) => Smiley.fromJson(smiley))
          .toList());

  List<Object> get props => [id, title, smilies];
}
