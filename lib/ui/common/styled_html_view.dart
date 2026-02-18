import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hkgalden_flutter/bloc/cubit/styled_html_view_cubit.dart';
import 'package:hkgalden_flutter/models/ui_state_models/styled_html_view_state.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/image_loading_error.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/utils/html_styles.dart';
import 'package:octo_image/octo_image.dart';

import 'package:url_launcher/url_launcher.dart';

class StyledHtmlView extends StatelessWidget {
  final String htmlString;
  final int floor;

  const StyledHtmlView(
      {super.key, required this.htmlString, required this.floor});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(1.0),
      ),
      child: BlocProvider(
        create: (context) => StyledHtmlViewCubit(),
        child: BlocBuilder<StyledHtmlViewCubit, StyledHtmlViewState>(
          builder: (context, state) => Html(
            data: htmlString,
            extensions: [
              TagExtension(
                tagsToExtend: {'img'},
                builder: (extensionContext) {
                  final src = extensionContext.attributes['src'] ?? '';
                  return Hero(
                    tag: '${floor}_${src}_$state.randomHash',
                    child: Stack(
                      children: [
                        OctoImage(
                          image: NetworkImage(src),
                          placeholderBuilder: (context) => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ProgressSpinner(),
                          ),
                          errorBuilder: (context, error, stackTrace) {
                            BlocProvider.of<StyledHtmlViewCubit>(context)
                                .setImageLoadingHasError(true);
                            return ImageLoadingError(error.toString());
                          },
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => state.imageLoadingHasError
                                  ? null
                                  : _showImageView(
                                      context,
                                      src,
                                      '${floor}_${src}_$state.randomHash',
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              TagExtension(
                tagsToExtend: {'icon'},
                builder: (extensionContext) {
                  final src = extensionContext.attributes['src'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: OctoImage(
                      image: NetworkImage(src),
                      placeholderBuilder: (context) => const SizedBox(),
                    ),
                  );
                },
              ),
            ],
            style: HtmlStyles.generate(context),
            onLinkTap: (url, _, __) => _launchURL(context, url!),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showImageView(BuildContext context, String url, String heroTag) {
    Navigator.of(context).push(
      FadeRoute(
        page: FullScreenPhotoView(
          heroTag: heroTag,
          url: url,
        ),
      ),
    );
  }
}
