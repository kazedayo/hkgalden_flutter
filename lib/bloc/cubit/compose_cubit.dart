import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/compose_state.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/networking/image_upload_api.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'dart:convert';

class ComposeCubit extends Cubit<ComposeState> {
  // Ultimately these should be passed in as a Repository,
  // but for now we route the direct API calls here to separate them from the UI.
  ComposeCubit() : super(ComposeInitial());

  Future<void> createThread(
      String title, String tagId, String quillContentStr) async {
    emit(ComposeSending());
    try {
      final htmlContent = await DeltaJsonParser()
          .toGaldenHtml(json.decode(quillContentStr) as List<dynamic>);

      final threadId =
          await HKGaldenApi().createThread(title, [tagId], htmlContent);

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
      final htmlContent = await DeltaJsonParser()
          .toGaldenHtml(json.decode(quillContentStr) as List<dynamic>);

      final sentReply = await HKGaldenApi().sendReply(
        threadId,
        htmlContent,
        parentId: parentId ?? '',
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

  Future<String> uploadImage(String filePath) async {
    return await ImageUploadApi().uploadImage(filePath);
  }
}
