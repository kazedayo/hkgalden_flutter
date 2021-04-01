import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/full_screen_photo_view_state.dart';

class FullScreenPhotoViewCubit extends Cubit<FullScreenPhotoViewState> {
  FullScreenPhotoViewCubit()
      : super(const FullScreenPhotoViewState(isDownloadingImage: false));

  void setIsDownloadingImage(bool newValue) =>
      emit(state.copyWith(isDownloadingImage: newValue));
}
