import 'package:equatable/equatable.dart';

class FullScreenPhotoViewState extends Equatable {
  final bool isSharingImage;
  final bool? shareFailed;

  const FullScreenPhotoViewState({
    required this.isSharingImage,
    this.shareFailed,
  });

  FullScreenPhotoViewState copyWith({
    bool? isSharingImage,
    bool? shareFailed,
  }) {
    return FullScreenPhotoViewState(
      isSharingImage: isSharingImage ?? this.isSharingImage,
      shareFailed: shareFailed,
    );
  }

  @override
  List<Object?> get props => [isSharingImage, shareFailed];
}
