import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/common/thread_tag_chip.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

class UserThreadListPage extends StatefulWidget {
  final String userId;

  const UserThreadListPage({super.key, required this.userId});

  @override
  State<UserThreadListPage> createState() => _UserThreadListPageState();
}

class _UserThreadListPageState extends State<UserThreadListPage> {
  bool _loading = true;
  bool _error = false;
  List<Thread> _userThreadList = const [];

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
    final List<Thread>? userThreadList =
        await RepositoryProvider.of<HKGaldenApi>(context)
            .getUserThreadList(widget.userId, 1);
    if (!mounted) {
      return;
    }
    if (userThreadList != null) {
      setState(() {
        _loading = false;
        _userThreadList = userThreadList;
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
    if (_loading) {
      return const ListLoadingSkeleton();
    }
    if (_error) {
      return ErrorPage(message: '無法載入主題列表', onRetry: _load);
    }
    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: _userThreadList.length,
      findChildIndexCallback: (Key key) {
        if (key is ValueKey<int>) {
          return _userThreadList.indexWhere(
            (thread) => thread.threadId == key.value,
          );
        }
        return null;
      },
      itemBuilder: (context, index) => Column(
        key: ValueKey(_userThreadList[index].threadId),
        children: <Widget>[
          ListTile(
            onTap: () => _openUserThread(_userThreadList[index]),
            title: Text(
              _userThreadList[index].title,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: ThreadTagChip(
              label: _userThreadList[index].tagName,
              backgroundColor: _userThreadList[index].tagColor,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 8,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }
}

/// Closes the user sheet, then pushes `/Thread`.
/// Tapping the thread already on screen only dismisses the sheet.
void _openUserThread(Thread thread) {
  final nav = navigatorKey.currentState;
  if (nav == null) {
    return;
  }

  var alreadyViewing = false;
  nav.popUntil((route) {
    if (route.settings.name == '/Thread') {
      final args = route.settings.arguments;
      if (args is ThreadPageArguments && args.threadId == thread.threadId) {
        alreadyViewing = true;
      }
      return true;
    }
    return route.isFirst;
  });

  if (alreadyViewing) {
    return;
  }

  nav.pushNamed('/Thread', arguments: ThreadPageArguments.fromThread(thread));
}
