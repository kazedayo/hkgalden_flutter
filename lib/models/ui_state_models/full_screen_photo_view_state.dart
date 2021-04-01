import 'package:equatable/equatable.dart';

class FullScreenPhotoViewState extends Equatable {
  final bool isDownloadingImage;

  const FullScreenPhotoViewState({required this.isDownloadingImage});

  FullScreenPhotoViewState copyWith({bool? isDownloadingImage}) {
    return FullScreenPhotoViewState(
        isDownloadingImage: isDownloadingImage ?? this.isDownloadingImage);
  }

  @override
  List<Object> get props => [isDownloadingImage];
}
