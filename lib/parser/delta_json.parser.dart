class DeltaJsonParser {
  String toGaldenHtml(List<dynamic> json) {
    String result = '';
    json.forEach((element) {
      //print(element);
      if (element['insert'] as String != '\n') {
        List<String> texts = (element['insert'] as String).split('\n');
        texts.forEach((element) {
          result += '<p>$element</p>';
        });
      }
    });
    print('<div id="pmc">${result.substring(0, result.length - 7)}</div>');
    return '<div id="pmc">${result.substring(0, result.length - 7)}</div>';
  }
}
