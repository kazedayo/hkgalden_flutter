import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/styled_html_view_state.dart';

class StyledHtmlViewCubit extends Cubit<StyledHtmlViewState> {
  StyledHtmlViewCubit()
      : super(StyledHtmlViewState(
            randomHash: Random().nextInt(1000), imageLoadingHasError: false));

  void setImageLoadingHasError(bool newValue) =>
      emit(state.copyWith(imageLoadingHasError: newValue));
}
