import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/smiley.dart';

class SmileyPack extends Equatable {
  final String id;
  final String title;
  final List<Smiley> smilies;

  const SmileyPack({
    this.id,
    this.title,
    this.smilies,
  });

  factory SmileyPack.fromJson(Map<String, dynamic> json) => SmileyPack(
      id: json['id'] as String,
      title: json['title'] as String,
      smilies: (json['smilies'] as List<dynamic>)
          .map((smiley) => Smiley.fromJson(smiley as Map<String, dynamic>))
          .toList());

  @override
  List<Object> get props => [id, title, smilies];
}
