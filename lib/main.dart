import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_reducer.dart';
import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_middleware.dart';
import 'package:hkgalden_flutter/redux/channel/channel_middleware.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_middleware.dart';
import 'package:hkgalden_flutter/redux/thread/thread_middleware.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_middleware.dart';
import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_middleware.dart';
import 'package:hkgalden_flutter/ui/startup_animation.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';
import 'package:paulonia_cache_image/paulonia_cache_image.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PCacheImage.init(enableInMemory: true);
  GestureBinding.instance.resamplingEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Store<AppState> store = Store<AppState>(
    appReducer,
    initialState: AppState.initial(),
    distinct: true,
    middleware: [
      ThreadListMiddleware(),
      ThreadMiddleware(),
      ChannelMiddleware(),
      SessionUserMiddleware(),
      BlockedUsersMiddleware(),
      UserThreadListMiddleware(),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
      store: store,
      child: MaterialApp(
        home: StartupScreen(),
        theme: _generateTheme(context),
        locale: const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
          Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
        ],
      ),
    );
  }

  ThemeData _generateTheme(BuildContext context) {
    final baseTheme = ThemeData(
      visualDensity: VisualDensity.compact,
      //materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      splashFactory: InkRipple.splashFactory,
      chipTheme: Theme.of(context).chipTheme.copyWith(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      dialogTheme: DialogTheme(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16))),
      ),
      brightness: Brightness.dark,
      popupMenuTheme: PopupMenuThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
      dividerColor: Colors.grey[800],
      primaryColor: const Color(0xff2e3533),
      scaffoldBackgroundColor: const Color(0xff1b1f1e),
      appBarTheme: const AppBarTheme(color: Color(0xff1b1f1e), elevation: 0),
      accentColor: const Color(0xff45c17c),
      cursorColor: const Color(0xff45c17c),
      textSelectionColor: const Color(0xff2d8052),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        focusElevation: 1,
        highlightElevation: 1,
        foregroundColor: Colors.white,
      ),
      cupertinoOverrideTheme:
          const CupertinoThemeData(primaryColor: Color(0xff45c17c)),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      }),
    );
    return baseTheme;
  }
}
