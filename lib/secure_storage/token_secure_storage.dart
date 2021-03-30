import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenSecureStorage {
  final storage = const FlutterSecureStorage();

  Future<void> writeToken(String value, {required Function onFinish}) async {
    await storage.write(key: 'token', value: value).then((value) {
      onFinish(value);
    });
  }

  Future<void> readToken({required Function onFinish}) async {
    await storage.read(key: 'token').then((value) {
      onFinish(value);
    });
  }
}
