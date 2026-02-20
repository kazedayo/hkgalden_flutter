import 'package:equatable/equatable.dart';

class FullScreenPhotoViewState extends Equatable {
  final bool isDownloadingImage;
  final bool? downloadSuccess;

  const FullScreenPhotoViewState({
    required this.isDownloadingImage,
    this.downloadSuccess,
  });

  FullScreenPhotoViewState copyWith({
    bool? isDownloadingImage,
    bool? downloadSuccess,
  }) {
    return FullScreenPhotoViewState(
      isDownloadingImage: isDownloadingImage ?? this.isDownloadingImage,
      downloadSuccess: downloadSuccess,
    );
  }

  @override
  List<Object?> get props => [isDownloadingImage, downloadSuccess];
}
