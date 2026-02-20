import 'dart:convert';

import 'package:http/http.dart' as http;

class ImageUploadApi {
  final url = 'https://api.na.cx/upload';

  Future<String> uploadImage(String localPath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Origin'] = 'https://hkgalden.org';
      request.files.add(await http.MultipartFile.fromPath('image', localPath));

      final responseStream = await request.send();
      final response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final imageUrl = responseJson['url'];
        if (imageUrl != null) {
          return imageUrl as String;
        } else {
          throw Exception('Missing URL in response');
        }
      } else {
        throw Exception(
            'Image upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }
}
