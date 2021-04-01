import 'package:equatable/equatable.dart';

class StartupScreenState extends Equatable {
  final String token;

  const StartupScreenState({required this.token});

  StartupScreenState copyWith({String? token}) {
    return StartupScreenState(token: token ?? this.token);
  }

  @override
  List<Object> get props => [token];
}
