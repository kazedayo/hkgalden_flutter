import 'package:bloc/bloc.dart';

part 'url_validation_state.dart';

class UrlValidationCubit extends Cubit<UrlValidationState> {
  UrlValidationCubit() : super(const UrlValidationState());

  void validateUrl(String text) {
    text = text.trim();
    final isValid = Uri.tryParse(text)?.hasAbsolutePath ?? false;
    emit(state.copyWith(
      isValidUrl: isValid,
      isUrlDirty: text.isNotEmpty,
    ));
  }
}
