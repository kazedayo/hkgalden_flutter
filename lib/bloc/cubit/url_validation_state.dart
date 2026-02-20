part of 'url_validation_cubit.dart';

class UrlValidationState {
  final bool isValidUrl;
  final bool isUrlDirty;

  const UrlValidationState({
    this.isValidUrl = false,
    this.isUrlDirty = false,
  });

  UrlValidationState copyWith({
    bool? isValidUrl,
    bool? isUrlDirty,
  }) {
    return UrlValidationState(
      isValidUrl: isValidUrl ?? this.isValidUrl,
      isUrlDirty: isUrlDirty ?? this.isUrlDirty,
    );
  }
}
