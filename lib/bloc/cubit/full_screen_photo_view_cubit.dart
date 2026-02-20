import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/full_screen_photo_view_state.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class FullScreenPhotoViewCubit extends Cubit<FullScreenPhotoViewState> {
  FullScreenPhotoViewCubit()
      : super(const FullScreenPhotoViewState(
            isDownloadingImage: false, downloadSuccess: null));

  void setIsDownloadingImage(bool newValue) =>
      emit(state.copyWith(isDownloadingImage: newValue));

  Future<void> saveImage(String url) async {
    emit(state.copyWith(isDownloadingImage: true, downloadSuccess: null));
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      var filePath = '${tempDir.path}/$fileName';

      if (!fileName.contains('.')) {
        filePath += '.jpg';
      }

      await Dio().download(url, filePath);
      await Gal.putImage(filePath);

      try {
        await File(filePath).delete();
      } catch (_) {}

      emit(state.copyWith(isDownloadingImage: false, downloadSuccess: true));
    } catch (e) {
      emit(state.copyWith(isDownloadingImage: false, downloadSuccess: false));
    }
  }
}
