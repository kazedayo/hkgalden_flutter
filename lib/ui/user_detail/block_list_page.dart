import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/common/blocked_user_cell.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/user_detail/blocked_users_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  bool _loading = true;
  bool _error = false;
  List<User> _blockedUsers = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final List<User>? blockedUsers =
        await RepositoryProvider.of<HKGaldenApi>(context).getBlockedUser();
    if (!mounted) {
      return;
    }
    if (blockedUsers != null) {
      setState(() {
        _loading = false;
        _blockedUsers = blockedUsers;
      });
    } else {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      color: Theme.of(context).primaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      elevation: 6,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height / 2,
        child: () {
          if (_loading) {
            return BlockedUsersLoadingSkeleton();
          }
          if (_error) {
            return ErrorPage(
              message: '無法載入封鎖名單',
              onRetry: _load,
            );
          }
          return ListView.builder(
            padding: EdgeInsets.only(
                top: 6,
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).padding.bottom),
            itemCount: _blockedUsers.length,
            findChildIndexCallback: (Key key) {
              if (key is ValueKey<String>) {
                return _blockedUsers
                    .indexWhere((user) => user.userId == key.value);
              }
              return null;
            },
            itemBuilder: (context, index) {
              return BlockedUserCell(
                  key: ValueKey(_blockedUsers[index].userId),
                  user: _blockedUsers[index]);
            },
          );
        }(),
      ),
    );
  }
}
