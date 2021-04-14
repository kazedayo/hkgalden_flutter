import 'package:equatable/equatable.dart';

class ThreadPageState extends Equatable {
  final bool onLastPage;
  final bool canReply;
  final double elevation;

  const ThreadPageState(
      {required this.onLastPage,
      required this.canReply,
      required this.elevation});

  ThreadPageState copyWith(
          {bool? onLastPage, bool? canReply, double? elevation}) =>
      ThreadPageState(
          onLastPage: onLastPage ?? this.onLastPage,
          canReply: canReply ?? this.canReply,
          elevation: elevation ?? this.elevation);

  @override
  List<Object> get props => [onLastPage, elevation];
}
