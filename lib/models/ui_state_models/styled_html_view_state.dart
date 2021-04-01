import 'package:equatable/equatable.dart';

class StyledHtmlViewState extends Equatable {
  final int randomHash;
  final bool imageLoadingHasError;

  const StyledHtmlViewState(
      {required this.randomHash, required this.imageLoadingHasError});

  StyledHtmlViewState copyWith({int? randomHash, bool? imageLoadingHasError}) {
    return StyledHtmlViewState(
        randomHash: randomHash ?? this.randomHash,
        imageLoadingHasError:
            imageLoadingHasError ?? this.imageLoadingHasError);
  }

  @override
  List<Object> get props => [randomHash, imageLoadingHasError];
}
