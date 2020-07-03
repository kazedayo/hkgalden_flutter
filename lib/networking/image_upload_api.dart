import 'dart:convert';

import 'package:http/http.dart' as http;

class ImageUploadApi {
  final url = 'https://api.na.cx/upload';

  Future<String> uploadImage(String localPath) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath('image', localPath));
    var response = await http.Response.fromStream(await request.send());
    var responseJson = jsonDecode(response.body);
    return responseJson['url'];
  }
}
