import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:meta/meta.dart';

@immutable
class UserThreadListState extends Equatable {
  final bool isLoading;
  final int page;
  final List<Thread> userThreadList;

  const UserThreadListState(
      {required this.isLoading,
      required this.page,
      required this.userThreadList});

  factory UserThreadListState.initial() => const UserThreadListState(
        isLoading: true,
        page: 1,
        userThreadList: [],
      );

  UserThreadListState copyWith({
    bool? isLoading,
    int? page,
    List<Thread>? userThreadList,
  }) =>
      UserThreadListState(
        isLoading: isLoading ?? this.isLoading,
        page: page ?? this.page,
        userThreadList: userThreadList ?? this.userThreadList,
      );

  @override
  List<Object> get props => [isLoading, page, userThreadList];
}
