import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class ReplyState extends Equatable {
  final bool isSending;

  ReplyState({this.isSending});

  factory ReplyState.initial() => ReplyState(
        isSending: false,
      );

  ReplyState copyWith(bool isSending) {
    return ReplyState(
      isSending: isSending ?? this.isSending,
    );
  }

  List<Object> get props => [isSending];
}
