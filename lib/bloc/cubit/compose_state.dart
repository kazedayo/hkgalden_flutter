import 'package:equatable/equatable.dart';

abstract class ComposeState extends Equatable {
  const ComposeState();

  @override
  List<Object> get props => [];
}

class ComposeInitial extends ComposeState {}

class ComposeSending extends ComposeState {}

class ComposeSuccess extends ComposeState {
  final dynamic result; // Can be a threadId (String) or a Reply

  const ComposeSuccess({this.result});

  @override
  List<Object> get props => [if (result != null) result!];
}

class ComposeFailure extends ComposeState {
  final String message;

  const ComposeFailure({required this.message});

  @override
  List<Object> get props => [message];
}
