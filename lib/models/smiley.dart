import 'package:equatable/equatable.dart';

class Smiley extends Equatable {
  final String id;
  final String alt;
  final int width;
  final int height;

  Smiley({this.id, this.alt, this.width, this.height});

  factory Smiley.fromJson(Map<String, dynamic> json) => Smiley(
      id: json['id'],
      alt: json['alt'],
      width: json['width'],
      height: json['height']);

  List<Object> get props => [id, alt, width, height];
}
