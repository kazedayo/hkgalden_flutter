import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/user_detail/block_list_page.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/utils/token_store.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'functions/home_page_jump_to_page.dart';
part 'functions/home_page_load_thread.dart';
part 'functions/home_page_scroll_controller_listener.dart';
part 'widgets/home_page_app_bar.dart';
part 'widgets/home_page_fab.dart';
part 'widgets/home_page_front_layer.dart';
part 'widgets/home_page_leading_button.dart';
part 'widgets/home_page_popup_menu_button.dart';

class HomePage extends StatefulWidget {
  final String? title;

  const HomePage({super.key, this.title});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    _initListener(context, _scrollController);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThreadListBloc threadListBloc =
        BlocProvider.of<ThreadListBloc>(context);
    final SessionUserBloc sessionUserBloc =
        BlocProvider.of<SessionUserBloc>(context);
    final ChannelBloc channelBloc = BlocProvider.of<ChannelBloc>(context);
    return BlocBuilder<ThreadListBloc, ThreadListState>(
      buildWhen: (prev, state) => prev != state,
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              BackdropScaffold(
                resizeToAvoidBottomInset: false,
                appBar: _buildAppBar(),
                frontLayer: _buildFrontLayer(
                    context,
                    threadListBloc,
                    channelBloc,
                    state,
                    sessionUserBloc,
                    _scrollController,
                    _loadThread,
                    _jumpToPage),
                frontLayerScrim: Colors.black.withAlpha(177),
                stickyFrontLayer: true,
                backLayer: HomeDrawer(),
                backLayerBackgroundColor:
                    Theme.of(context).scaffoldBackgroundColor,
                floatingActionButton: _buildFab(context, threadListBloc),
              ),
            ],
          ),
        );
      },
    );
  }
}
