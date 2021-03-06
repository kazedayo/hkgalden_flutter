import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DeltaJsonParser {
  Future<String> toGaldenHtml(List<dynamic> json) async {
    String result = '';
    String row = '';
    String styledInsert = '';
    await Future.forEach(json, (element) async {
      //print(element);
      if (element['insert'].contains('\n') == false ||
          element['insert'] == '\n') {
        styledInsert = element['insert'] == '\n'
            ? styledInsert
            : element['insert'] as String;
        if (element['attributes'] != null) {
          //print(element['insert']);
          await Future.forEach(
              (element['attributes'] as Map<String, dynamic>).entries,
              (entry) async {
            switch (entry.key as String) {
              case 'a':
                styledInsert =
                    '<span data-nodetype="a" data-href="${entry.value}">$styledInsert</span>';
                break;
              case 'b':
                styledInsert = '<span data-nodetype="b">$styledInsert</span>';
                break;
              case 'i':
                styledInsert = '<span data-nodetype="i">$styledInsert</span>';
                break;
              case 'u':
                styledInsert = '<span data-nodetype="u">$styledInsert</span>';
                break;
              case 's':
                styledInsert = '<span data-nodetype="s">$styledInsert</span>';
                break;
              case 'heading':
                //heading自成一行
                row = '';
                styledInsert =
                    '<span data-nodetype="h${entry.value}">$styledInsert</span>';
                break;
              case 'embed':
                if (entry.value['type'] == 'image') {
                  await _getImageDimension(entry.value['source'] as String)
                      .then((image) => styledInsert =
                          '<span data-nodetype="img" data-src="${entry.value['source']}" data-sx="${image.width}" data-sy="${image.height}"></span>');
                }
                break;
              default:
            }
          });
          row += styledInsert;
          if (element['insert'] == '\n') {
            //heading自成一行
            result += '<p>$row</p>';
            row = '';
          }
        } else {
          //for 混排
          row += element['insert'] as String;
        }
      } else {
        final List<String> texts =
            element['insert'].split('\n') as List<String>;
        //print(texts.length);
        if (texts.length == 2) {
          row += texts.first;
          //save old row and start new row
          result += '<p>$row</p>';
          row = '';
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
    return '<div id="pmc">${result.replaceAll('<p></p>', '')}</div>';
  }

  Future<ui.Image> _getImageDimension(String url) {
    final Completer<ui.Image> imageCompleter = Completer<ui.Image>();
    NetworkImage(url)
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      imageCompleter.complete(info.image);
    }));
    return imageCompleter.future;
  }
}
