class DeltaJsonParser {
  String toGaldenHtml(List<dynamic> json) {
    String result = '';
    print(json);
    String row = '';
    json.forEach((element) {
      //print(element);
      if (!(element['insert'] as String).contains('\n')) {
        if (element['attributes'] != null) {
          //print(element['insert']);
          String styledInsert = element['insert'];
          (element['attributes'] as Map<String, dynamic>).forEach((key, value) {
            switch (key) {
              case 'b':
                styledInsert = '<span data-nodetype="b">$styledInsert</span>';
                break;
              case 'i':
                styledInsert = '<span data-nodetype="i">$styledInsert</span>';
                break;
              case 'heading':
                styledInsert =
                    '<span data-nodetype="h${value as String}">$styledInsert</span>';
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
    //print('<div id="pmc">${result.replaceAll('<p></p>', '')}</div>');
    return '<div id="pmc">${result.replaceAll('<p></p>', '')}</div>';
  }
}
