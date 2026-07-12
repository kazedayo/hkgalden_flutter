import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/compose_state.dart';
import 'package:hkgalden_flutter/networking/image_upload_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';

class ComposeCubit extends Cubit<ComposeState> {
  ComposeCubit({
    required ThreadRepository threadRepository,
    ImageUploadApi? imageUploadApi,
    DeltaJsonParser? deltaJsonParser,
  })  : _threadRepository = threadRepository,
        _imageUploadApi = imageUploadApi ?? ImageUploadApi(),
        _deltaJsonParser = deltaJsonParser ?? DeltaJsonParser(),
        super(ComposeInitial());

  final ThreadRepository _threadRepository;
  final ImageUploadApi _imageUploadApi;
  final DeltaJsonParser _deltaJsonParser;

  Future<void> createThread(
      String title, String tagId, String quillContentStr) async {
    emit(ComposeSending());
    try {
      final htmlContent = await _deltaJsonParser
          .toGaldenHtml(json.decode(quillContentStr) as List<dynamic>);

      final threadId =
          await _threadRepository.createThread(title, [tagId], htmlContent);

      if (threadId != null) {
        emit(ComposeSuccess(result: threadId));
      } else {
        emit(const ComposeFailure(message: '主題發表失敗!'));
      }
    } catch (e) {
      emit(const ComposeFailure(message: '主題發表失敗!'));
    }
  }

  Future<void> sendReply(int threadId, String quillContentStr,
      {String? parentId}) async {
    emit(ComposeSending());
    try {
      final htmlContent = await _deltaJsonParser
          .toGaldenHtml(json.decode(quillContentStr) as List<dynamic>);

      final sentReply = await _threadRepository.sendReply(
        threadId,
        htmlContent,
        parentId: parentId,
      );

      if (sentReply != null) {
        emit(ComposeSuccess(result: sentReply));
      } else {
        emit(const ComposeFailure(message: '回覆發送失敗!'));
      }
    } catch (e) {
      emit(const ComposeFailure(message: '回覆發送失敗!'));
    }
  }

  Future<String> uploadImage(String filePath) {
    return _imageUploadApi.uploadImage(filePath);
  }
}
