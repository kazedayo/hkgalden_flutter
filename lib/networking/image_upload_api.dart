import 'dart:convert';

import 'package:http/http.dart' as http;

class ImageUploadApi {
  final url = 'https://api.na.cx/upload';

  Future<String> uploadImage(String localPath) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('image', localPath));
    final response = await http.Response.fromStream(await request.send());
    final responseJson = jsonDecode(response.body);
    return responseJson['url'] as String;
  }
}
