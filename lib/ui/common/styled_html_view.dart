import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hkgalden_flutter/utils/html_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class StyledHtmlView extends StatelessWidget {
  final String htmlString;

  const StyledHtmlView({super.key, required this.htmlString, int? floor});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(1.0),
      ),
      child: SelectionArea(
        child: Html(
          data: htmlString,
          style: HtmlStyles.generate(context),
          extensions: [
            TagExtension(
              tagsToExtend: {'icon'},
              builder: (extensionContext) {
                final src = extensionContext.attributes['src'] ?? '';
                if (src.isEmpty) {
                  return const SizedBox.shrink();
                }
                final cachePx =
                    (48 * MediaQuery.devicePixelRatioOf(context)).round();
                return Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Image(
                    image: ResizeImage(
                      NetworkImage(src),
                      width: cachePx,
                      height: cachePx,
                    ),
                    gaplessPlayback: true,
                    loadingBuilder: (context, child, loading) =>
                        loading == null ? child : const SizedBox(),
                  ),
                );
              },
            ),
          ],
          onLinkTap: (url, attributes, element) => _launchURL(url!),
        ),
      ),
    );
  }

  static Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
}
