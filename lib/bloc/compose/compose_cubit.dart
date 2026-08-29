import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/compose/compose_state.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class ComposeCubit extends Cubit<ComposeState> {
  ComposeCubit({
    required HKGaldenApi api,
    DeltaJsonParser? deltaJsonParser,
  })  : _api = api,
        _deltaJsonParser = deltaJsonParser ?? DeltaJsonParser(),
        super(ComposeInitial());

  final HKGaldenApi _api;
  final DeltaJsonParser _deltaJsonParser;

  Future<void> createThread(
      String title, String tagId, String quillContentStr) async {
    await _compose(
      quillContentStr,
      '主題發表失敗!',
      (htmlContent) => _api.createThread(title, [tagId], htmlContent),
    );
  }

  Future<void> sendReply(int threadId, String quillContentStr,
      {String? parentId}) async {
    await _compose(
      quillContentStr,
      '回覆發送失敗!',
      (htmlContent) =>
          _api.sendReply(threadId, htmlContent, parentId: parentId),
    );
  }

  Future<void> _compose<T>(String quillContentStr, String failureMessage,
      Future<T?> Function(String htmlContent) action) async {
    emit(ComposeSending());
    try {
      final htmlContent = await _deltaJsonParser
          .toGaldenHtml(json.decode(quillContentStr) as List<dynamic>);

      final result = await action(htmlContent);

      if (result != null) {
        emit(ComposeSuccess(result: result));
      } else {
        emit(ComposeFailure(message: failureMessage));
      }
    } catch (e) {
      emit(ComposeFailure(message: failureMessage));
    }
  }
}
