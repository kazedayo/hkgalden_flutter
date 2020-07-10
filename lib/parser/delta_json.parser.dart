import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DeltaJsonParser {
  Future<String> toGaldenHtml(List<dynamic> json) async {
    String result = '';
    print(json);
    String row = '';
    await Future.forEach(json, (element) async {
      //print(element);
      if (!(element['insert'] as String).contains('\n')) {
        if (element['attributes'] != null) {
          //print(element['insert']);
          String styledInsert = element['insert'];
          await Future.forEach(
              (element['attributes'] as Map<String, dynamic>).entries,
              (entry) async {
            switch (entry.key) {
              case 'b':
                styledInsert = '<span data-nodetype="b">$styledInsert</span>';
                break;
              case 'i':
                styledInsert = '<span data-nodetype="i">$styledInsert</span>';
                break;
              case 'heading':
                styledInsert =
                    '<span data-nodetype="h${entry.value as String}">$styledInsert</span>';
                break;
              case 'embed':
                if (entry.value['type'] == 'image') {
                  await _getImageDimension(entry.value['source']).then(
                      (image) => styledInsert =
                          '<span data-nodetype="img" data-src="${entry.value['source']}" data-sx="${image.width}" data-sy="${image.height}"></span>');
                }
                break;
              default:
            }
          });
          row += styledInsert;
        } else {
          row += element['insert'];
        }
      } else {
        List<String> texts = (element['insert'] as String).split('\n');
        //print(texts.length);
        if (texts.length == 2) {
          row += texts.first;
          result += '<p>$row</p>';
        } else {
          texts.forEach((element) {
            //save old row and start new row
            result += '<p>$row</p>';
            row = '';
            //print(element);
            result += '<p>$element</p>';
          });
        }
      }
    });
    print('<div id="pmc">${result.replaceAll('<p></p>', '')}</div>');
    return '<div id="pmc">${result.replaceAll('<p></p>', '')}</div>';
  }

  Future<ui.Image> _getImageDimension(String url) {
    Completer<ui.Image> imageCompleter = Completer<ui.Image>();
    CachedNetworkImageProvider(url)
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      imageCompleter.complete(info.image);
    }));
    return imageCompleter.future;
  }
}
