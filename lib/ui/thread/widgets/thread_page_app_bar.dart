part of '../thread_page.dart';

Widget _buildAppBar(BuildContext context, ThreadPageArguments arguments) {
  return BlocBuilder<ThreadPageCubit, ThreadPageState>(
    builder: (context, state) => AppBar(
      elevation: state.elevation,
      automaticallyImplyLeading: false,
      leading: IconButton(
          icon: Icon(Theme.of(context).platform == TargetPlatform.iOS
              ? Icons.arrow_back_ios_rounded
              : Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop()),
      title: SizedBox(
        height: kToolbarHeight * 0.85,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: AutoSizeText(
                arguments.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
                maxLines: 2,
                minFontSize: 14,
                maxFontSize: 19,
                //overflow: TextOverflow.ellipsis
              ),
            )
          ],
        ),
      ),
      actions: [
        Visibility(
          visible: arguments.locked,
          child: const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.lock_rounded),
          ),
        )
      ],
    ),
  );
}
