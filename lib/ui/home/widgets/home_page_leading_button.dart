part of '../home_page.dart';

class _LeadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.close_menu,
          progress: Backdrop.of(context).animationController.view,
        ),
        onPressed: () => Backdrop.of(context).fling(),
      );
}
