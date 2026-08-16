import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_document.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_js.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_messages.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_shell.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_theme.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:hkgalden_flutter/models/ui_state_models/thread_page_state.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_on_reply_success.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';
import 'package:hkgalden_flutter/utils/thread_reading_position_store.dart';
import 'package:hkgalden_flutter/utils/x_status_cache.dart';
import 'package:hkgalden_flutter/utils/youtube_oembed_cache.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const double kThreadPageLoadMoreThreshold = 480;

class ThreadWebViewController {
  _ThreadWebViewState? _client;

  int? cachedLastFloor;
  int? threadId;
  bool hasRendered = false;
  final ValueNotifier<bool> contentReady = ValueNotifier<bool>(false);

  void dispose() {
    contentReady.dispose();
  }

  void _attach(_ThreadWebViewState client) {
    _client = client;
    cachedLastFloor = client.cachedLastFloor;
  }

  void _detach(_ThreadWebViewState client) {
    if (identical(_client, client)) {
      _client = null;
    }
  }

  void persist({required double safeBottom, bool remeasure = true}) {
    final client = _client;
    if (client != null) {
      client.persist(safeBottom: safeBottom, remeasure: remeasure);
      cachedLastFloor = client.cachedLastFloor;
      return;
    }
    persistFromCache();
  }

  void persistFromCache() {
    final floor = cachedLastFloor;
    final id = threadId;
    if (!hasRendered || floor == null || id == null) {
      return;
    }
    ThreadReadingPositionStore.instance.save(
      id,
      page: ThreadReadingPosition.pageForFloor(floor),
      floor: floor,
    );
  }

  void scrollToBottom() {
    _client?._js.send('scrollToBottom');
  }
}

class ThreadWebView extends StatefulWidget {
  final ThreadWebViewController controller;
  final int? restoreFloor;
  final PreviousPagePullController previousPull;

  const ThreadWebView({
    super.key,
    required this.controller,
    required this.previousPull,
    this.restoreFloor,
  });

  @override
  State<ThreadWebView> createState() => _ThreadWebViewState();
}

class _ThreadWebViewState extends State<ThreadWebView> {
  late final WebViewController _webViewController;
  late final ThreadWebViewJs _js;
  late final ThreadWebViewDocument _document;

  final Map<int, Reply> _repliesByFloor = {};
  final Map<String, Reply> _repliesById = {};
  final Map<String, User> _authors = {};

  int? cachedLastFloor;
  bool _didInitialRender = false;
  int _renderedPreviousCount = 0;
  int _renderedMainCount = 0;
  int? _renderedEndPage;
  bool _loadMoreSent = false;
  double _lastScrollY = 0;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    cachedLastFloor = widget.restoreFloor;
    widget.controller.cachedLastFloor = cachedLastFloor;
    _document = const ThreadWebViewDocument();
    _js = ThreadWebViewJs();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigation),
      )
      ..addJavaScriptChannel(
        'Galden',
        onMessageReceived: (message) {
          final inbound = ThreadWebViewInbound.tryParse(message.message);
          if (inbound != null && mounted) {
            _onInbound(inbound);
          }
        },
      );
    _js.attach(_webViewController);
    _loadShell();
  }

  Future<void> _loadShell() async {
    final html = await loadThreadWebViewShell();
    if (!mounted) {
      return;
    }
    await _webViewController.loadHtmlString(html);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_js.isReady) {
      final padding = MediaQuery.viewPaddingOf(context);
      _js.send('setSafeInsets', {
        'left': padding.left,
        'right': padding.right,
        'bottom': padding.bottom,
      });
    }
  }

  @override
  void didUpdateWidget(covariant ThreadWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    super.dispose();
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    if (isHttpOrHttpsUrl(request.url)) {
      _launchUrl(request.url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _indexReplies(Iterable<Reply> replies) {
    for (final reply in replies) {
      _repliesByFloor[reply.floor] = reply;
      final id = reply.replyId;
      if (id != null && id.isNotEmpty) {
        _repliesById[id] = reply;
      }
      _authors[reply.author.userId] = reply.author;
    }
  }

  List<ThreadWebViewReplyDto> _dtoList(
    Iterable<Reply> replies,
    SessionUserState session,
  ) {
    return _document.serializeReplies(replies, session);
  }

  void _pushThemeAndChrome(ThreadLoaded state, SessionUserState session) {
    final padding = MediaQuery.viewPaddingOf(context);
    _js.send('setTheme', threadWebViewThemeTokens());
    _js.send('setSafeInsets', {
      'left': padding.left,
      'right': padding.right,
      'bottom': padding.bottom,
    });
    _js.send('setFlags', _flags(state));
    _js.send('setBlockedUsers', {
      'ids': _blockedIds(session),
    });
  }

  Map<String, dynamic> _flags(ThreadLoaded state) {
    final pageState = context.read<ThreadPageCubit>().state;
    return {
      'canReply': pageState.canReply,
      'locked': state.thread.status == 'locked',
      'onLastPage': pageState.onLastPage,
      'appending': false,
      'currentPage': state.currentPage,
      'canPullPrevious': state.currentPage > 1,
      'pullMaxExtent': PreviousPagePullController.maxExtent,
      'platform': Theme.of(context).platform == TargetPlatform.iOS
          ? 'ios'
          : 'android',
    };
  }

  List<String> _blockedIds(SessionUserState session) {
    if (session is SessionUserLoaded) {
      return List<String>.from(session.sessionUser.blockedUsers);
    }
    return const [];
  }

  Future<void> _renderInitial(
    ThreadLoaded state,
    SessionUserState session,
  ) async {
    widget.controller.threadId = state.thread.threadId;
    _indexReplies(state.previousPages.replies);
    _indexReplies(state.thread.replies);
    _pushThemeAndChrome(state, session);
    final previous = _dtoList(state.previousPages.replies, session);
    final replies = _dtoList(state.thread.replies, session);
    await _js.send('renderThread', {
      'previous': [for (final dto in previous) dto.toJson()],
      'replies': [for (final dto in replies) dto.toJson()],
      if (widget.restoreFloor != null && widget.restoreFloor! >= 1)
        'scrollToFloor': widget.restoreFloor,
    });
    _didInitialRender = true;
    widget.controller.hasRendered = true;
    _renderedPreviousCount = state.previousPages.replies.length;
    _renderedMainCount = state.thread.replies.length;
    _renderedEndPage = state.endPage;
    _markContentReady();
    if (!mounted) {
      return;
    }
    _hydratePreviews([...previous, ...replies]);
    _loadMoreSent = false;
  }

  void _markContentReady() {
    if (!widget.controller.contentReady.value) {
      widget.controller.contentReady.value = true;
    }
  }

  void _syncLoaded(ThreadLoaded state) {
    if (!_js.isReady) {
      return;
    }
    final session = context.read<SessionUserBloc>().state;
    if (!_didInitialRender) {
      _renderInitial(state, session);
      return;
    }

    _js.send('setFlags', _flags(state));

    final previous = state.previousPages.replies;
    if (previous.length > _renderedPreviousCount) {
      final added = previous.sublist(
        0,
        previous.length - _renderedPreviousCount,
      );
      _indexReplies(added);
      final dtos = _dtoList(added, session);
      _js.send('prependReplies', {
        'replies': [for (final dto in dtos) dto.toJson()],
      });
      _renderedPreviousCount = previous.length;
      widget.previousPull.finishLoading();
      _hydratePreviews(dtos);
    } else if (widget.previousPull.loading) {
      widget.previousPull.finishLoading();
      _js.send('resetPull');
    }

    if (state.endPage > (_renderedEndPage ?? state.endPage) ||
        state.thread.replies.length > _renderedMainCount) {
      if (state.endPage == _renderedEndPage &&
          state.currentPage == state.endPage &&
          state.thread.replies.length != _renderedMainCount + 1) {
        _replaceMain(state, session);
      } else if (state.thread.replies.length >= _renderedMainCount) {
        final added = state.thread.replies.sublist(_renderedMainCount);
        if (added.isNotEmpty) {
          _indexReplies(added);
          final dtos = _dtoList(added, session);
          _js.send('appendReplies', {
            'replies': [for (final dto in dtos) dto.toJson()],
          });
          _hydratePreviews(dtos);
        } else if (state.currentPage == state.endPage &&
            state.thread.replies.length != _renderedMainCount) {
          _replaceMain(state, session);
        }
      } else {
        _replaceMain(state, session);
      }
      _renderedMainCount = state.thread.replies.length;
      _renderedEndPage = state.endPage;
      _loadMoreSent = false;
    } else if (state.endPage == _renderedEndPage &&
        state.currentPage == state.endPage &&
        state.thread.replies.length != _renderedMainCount) {
      _replaceMain(state, session);
      _renderedMainCount = state.thread.replies.length;
      _loadMoreSent = false;
    }
  }

  void _replaceMain(ThreadLoaded state, SessionUserState session) {
    _indexReplies(state.thread.replies);
    final dtos = _dtoList(state.thread.replies, session);
    _js.send('replaceLastPage', {
      'replies': [for (final dto in dtos) dto.toJson()],
    });
    _hydratePreviews(dtos);
  }

  void _hydratePreviews(Iterable<ThreadWebViewReplyDto> dtos) {
    final youtubeIds = <String>{};
    final xIds = <String>{};
    for (final dto in dtos) {
      youtubeIds.addAll(dto.youtubeIds);
      xIds.addAll(dto.xIds);
    }
    for (final id in youtubeIds) {
      YoutubeOEmbedCache.instance.fetch(id).then((info) {
        if (!mounted || info == null) {
          return;
        }
        _js.send('hydratePreviews', {
          'items': [
            {
              'kind': 'youtube',
              'id': id,
              'title': info.title,
              'subtitle': info.authorName ?? 'youtube.com',
              if (info.thumbnailUrl != null) 'imageUrl': info.thumbnailUrl,
            },
          ],
        });
      });
    }
    for (final id in xIds) {
      XStatusCache.instance.fetch(id).then((info) {
        if (!mounted || info == null) {
          return;
        }
        _js.send('hydratePreviews', {
          'items': [
            {
              'kind': 'x',
              'id': id,
              'title': info.authorName,
              'subtitle': info.authorScreenName != null
                  ? '@${info.authorScreenName}'
                  : 'x.com',
              'body': info.text,
              if (info.imageUrl != null) 'imageUrl': info.imageUrl,
            },
          ],
        });
      });
    }
  }

  Future<void> _onJsReady() async {
    await _js.onReady();
    if (!mounted) {
      return;
    }
    final state = context.read<ThreadBloc>().state;
    if (state is ThreadLoaded) {
      await _renderInitial(state, context.read<SessionUserBloc>().state);
    }
  }

  void _onInbound(ThreadWebViewInbound message) {
    switch (message.type) {
      case 'ready':
        _onJsReady();
      case 'contentReady':
        _markContentReady();
      case 'openLink':
        final url = message.string('url');
        if (url != null) {
          _launchUrl(url);
        }
      case 'openImage':
        _openImage(message);
      case 'quote':
        _quote(message);
      case 'openUser':
        _openUser(message.string('userId'));
      case 'scroll':
        _onScroll(message);
      case 'pullPrevious':
        final phase = message.string('phase') ?? '';
        widget.previousPull.handleJsPull(
          phase: phase,
          threadBloc: context.read<ThreadBloc>(),
        );
        if (phase == 'load' && !widget.previousPull.loading) {
          _js.send('resetPull');
        }
      case 'refreshLastPage':
        final state = context.read<ThreadBloc>().state;
        if (state is ThreadLoaded) {
          context.read<ThreadBloc>().add(RequestThreadEvent(
                threadId: state.thread.threadId,
                page: state.endPage,
                isInitialLoad: false,
              ));
        }
      case 'imageMetrics':
        _saveImageMetrics(message);
      default:
        break;
    }
  }

  void _onScroll(ThreadWebViewInbound message) {
    final y = message.decimal('y') ?? 0;
    final maxY = message.decimal('maxY') ?? 0;
    final atEnd = message.flag('atEnd');
    final settled = message.flag('settled');
    final topFloor = message.integer('viewportTopFloor');
    final lastVisible = message.integer('lastVisibleFloor');

    final cubit = context.read<ThreadPageCubit>();
    final elevation = y > 0 ? 4.0 : 0.0;
    if (elevation != cubit.state.elevation) {
      cubit.setElevation(elevation);
    }

    final scrollingDown = y > _lastScrollY + 0.5;
    _lastScrollY = y;

    final bloc = context.read<ThreadBloc>();
    final state = bloc.state;
    if (state is ThreadLoaded &&
        scrollingDown &&
        !cubit.state.onLastPage &&
        !_loadMoreSent &&
        y >= maxY - kThreadPageLoadMoreThreshold) {
      _loadMoreSent = true;
      bloc.add(RequestThreadEvent(
        threadId: state.thread.threadId,
        page: state.endPage + 1,
        isInitialLoad: false,
      ));
    }

    final lastLoaded = state is ThreadLoaded && state.thread.replies.isNotEmpty
        ? state.thread.replies.last.floor
        : null;
    final floor = ThreadReadingPosition.resolveFloorForPersistence(
      viewportTopFloor: topFloor,
      lastVisibleFloor: lastVisible,
      lastLoadedFloor: lastLoaded,
      atTrailingEdge: atEnd,
    );
    if (floor != null) {
      cachedLastFloor = floor;
      widget.controller.cachedLastFloor = floor;
    }

    if (settled) {
      persist(safeBottom: MediaQuery.viewPaddingOf(context).bottom);
    }
  }

  void persist({required double safeBottom, bool remeasure = true}) {
    final state = context.read<ThreadBloc>().state;
    if (state is! ThreadLoaded) {
      return;
    }
    final resolved = cachedLastFloor ??
        (state.thread.replies.isNotEmpty
            ? state.thread.replies.last.floor
            : null);
    if (resolved == null) {
      return;
    }
    cachedLastFloor = resolved;
    widget.controller.cachedLastFloor = resolved;
    ThreadReadingPositionStore.instance.save(
      state.thread.threadId,
      page: ThreadReadingPosition.pageForFloor(resolved),
      floor: resolved,
    );
    if (!remeasure) {
      ThreadReadingPositionStore.instance.flush();
    }
  }

  void _openImage(ThreadWebViewInbound message) {
    final url = message.string('url');
    if (url == null || !isHttpOrHttpsUrl(url)) {
      return;
    }
    FullScreenPhotoView.open(
      context,
      url: url,
      intrinsicWidth: message.integer('sx'),
      intrinsicHeight: message.integer('sy'),
    );
  }

  void _quote(ThreadWebViewInbound message) {
    final pageState = context.read<ThreadPageCubit>().state;
    if (!pageState.canReply) {
      showCustomAlert(
        context: context,
        title: '未登入',
        content: '請先登入',
      );
      return;
    }
    final replyId = message.string('replyId');
    final floor = message.integer('floor');
    final reply = (replyId != null ? _repliesById[replyId] : null) ??
        (floor != null ? _repliesByFloor[floor] : null);
    if (reply == null) {
      return;
    }
    final state = context.read<ThreadBloc>().state;
    if (state is! ThreadLoaded) {
      return;
    }
    showBarModalBottomSheet(
      duration: const Duration(milliseconds: 300),
      animationCurve: Curves.easeOut,
      context: context,
      builder: (context) => ComposePage(
        composeMode: ComposeMode.quotedReply,
        threadId: state.thread.threadId,
        parentReply: reply,
        onSent: (sent) {
          onThreadReplySuccess(
            this.context,
            widget.controller,
            sent,
            pageState.onLastPage,
          );
        },
      ),
    );
  }

  void _openUser(String? userId) {
    if (userId == null) {
      return;
    }
    final user = _authors[userId];
    if (user == null) {
      return;
    }
    showMaterialModalBottomSheet(
      duration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeOut,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      context: context,
      enableDrag: false,
      builder: (context) => UserPage(user: user),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!isHttpOrHttpsUrl(url)) {
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _saveImageMetrics(ThreadWebViewInbound message) {
    final url = message.string('url');
    final width = message.decimal('width');
    final height = message.decimal('height');
    if (url == null || width == null || height == null) {
      return;
    }
    final ratio = ImageAspectRatioStore.aspectRatioFromSize(width, height);
    if (ratio == null) {
      return;
    }
    ImageAspectRatioStore.instance.save(url, ratio, naturalWidth: width);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ThreadBloc, ThreadState>(
          listener: (context, state) {
            if (state is ThreadAppending) {
              _js.send('setFlags', {'appending': true});
            } else if (state is ThreadLoaded) {
              _syncLoaded(state);
            }
          },
        ),
        BlocListener<ThreadPageCubit, ThreadPageState>(
          listenWhen: (prev, next) =>
              prev.canReply != next.canReply ||
              prev.onLastPage != next.onLastPage,
          listener: (context, _) {
            final state = context.read<ThreadBloc>().state;
            if (state is ThreadLoaded && _js.isReady) {
              _js.send('setFlags', _flags(state));
            }
          },
        ),
        BlocListener<SessionUserBloc, SessionUserState>(
          listener: (context, session) {
            if (_js.isReady) {
              _js.send('setBlockedUsers', {'ids': _blockedIds(session)});
            }
          },
        ),
      ],
      child: WebViewWidget(controller: _webViewController),
    );
  }
}
