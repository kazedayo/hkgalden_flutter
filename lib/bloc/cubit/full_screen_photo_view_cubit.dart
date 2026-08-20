import 'dart:io';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/full_screen_photo_view_state.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenPhotoViewCubit extends Cubit<FullScreenPhotoViewState> {
  FullScreenPhotoViewCubit()
      : super(const FullScreenPhotoViewState(isSharingImage: false));

  Future<void> shareImage(String url, {Rect? sharePositionOrigin}) async {
    emit(state.copyWith(isSharingImage: true, shareFailed: null));
    String? filePath;
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = _fileNameFor(url);
      filePath = '${tempDir.path}/$fileName';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('download failed');
      }
      await File(filePath).writeAsBytes(response.bodyBytes);
      if (isClosed) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: _mimeTypeFor(fileName))],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      emit(state.copyWith(isSharingImage: false));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(isSharingImage: false, shareFailed: true));
      }
    } finally {
      final path = filePath;
      if (path != null) {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }
  }

  static String _fileNameFor(String url) {
    final uri = Uri.tryParse(url);
    var name = (uri != null && uri.pathSegments.isNotEmpty)
        ? uri.pathSegments.last
        : url.split('/').last;
    name = name.split('?').first;
    if (name.isEmpty || !name.contains('.')) {
      return 'image.jpg';
    }
    return name;
  }

  static String _mimeTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}
