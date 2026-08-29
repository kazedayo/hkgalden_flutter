import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/user_avatar_image.dart';
import 'package:hkgalden_flutter/ui/user_detail/block_list_page.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class UserPage extends StatefulWidget {
  final User user;

  const UserPage({super.key, required this.user});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final PageController _pageController = PageController();
  int _page = 0;
  bool _blocking = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isOwnProfile(SessionUserState session) {
    return session is SessionUserLoaded &&
        session.sessionUser.userId == widget.user.userId;
  }

  void _selectPage(int page) {
    setState(() => _page = page);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _blockUser() async {
    final session = context.read<SessionUserCubit>();
    if (session.state is! SessionUserLoaded) {
      showLoginRequired(context);
      return;
    }
    if (_blocking) {
      return;
    }
    setState(() => _blocking = true);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await session.appendUserToBlockList(widget.user.userId);
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('已封鎖會員 ${widget.user.nickName}')),
      );
      return;
    }
    setState(() => _blocking = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('封鎖失敗')),
    );
  }

  Widget _chip({
    required ThemeData theme,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final selectedColor = theme.colorScheme.secondary;
    final unselectedColor = AppTheme.linkPreviewBackground(theme.colorScheme);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? selectedColor
            : unselectedColor,
      ),
      labelStyle: theme.textTheme.labelSmall!.copyWith(
        color: selected
            ? theme.colorScheme.onSecondary
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionUserCubit>().state;
    final theme = Theme.of(context);
    final ownProfile = _isOwnProfile(session);

    return SizedBox.expand(
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.hardEdge,
            color: theme.primaryColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusLarge),
                topRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            elevation: 6,
            margin: const EdgeInsets.only(top: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      _chip(
                        theme: theme,
                        label: '主題列表',
                        selected: _page == 0,
                        onSelected: () => _selectPage(0),
                      ),
                      if (ownProfile) ...[
                        const SizedBox(width: 8),
                        _chip(
                          theme: theme,
                          label: '封鎖名單',
                          selected: _page == 1,
                          onSelected: () => _selectPage(1),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ownProfile
                      ? PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            UserThreadListPage(userId: widget.user.userId),
                            const BlockListPage(),
                          ],
                        )
                      : UserThreadListPage(userId: widget.user.userId),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 12,
            right: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatarImage(
                  avatarUrl: widget.user.avatar,
                  userGroup: widget.user.userGroup,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.nickName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          height: 1.2,
                          color: widget.user.gender == 'M'
                              ? AppTheme.brotherColor
                              : AppTheme.sisterColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.user.userId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall!.copyWith(
                          height: 1.2,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!ownProfile) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.redAccent,
                    elevation: 6,
                    shadowColor: Colors.black54,
                    shape: const StadiumBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _blocking ? null : _blockUser,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(10, 6, 12, 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '封鎖',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
