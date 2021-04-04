import 'package:hive/hive.dart';

class TokenStore {
  final tokenBox = Hive.box('token');

  Future<void> writeToken(String value) async {
    await tokenBox.put('token', value);
    return;
  }

  Future<String?> readToken() async {
    final String? token = await tokenBox.get('token') as String?;
    return token;
  }
}
