import 'package:equatable/equatable.dart';

class Smiley extends Equatable {
  final String id;
  final String alt;
  final int width;
  final int height;

  const Smiley(
      {required this.id,
      required this.alt,
      required this.width,
      required this.height});

  factory Smiley.fromJson(Map<String, dynamic> json) => Smiley(
      id: json['id'] as String,
      alt: json['alt'] as String,
      width: json['width'] as int,
      height: json['height'] as int);

  @override
  List<Object> get props => [id, alt, width, height];
}
