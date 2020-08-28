import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

void main() => runApp(MyApp());

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
        theme: _generateTheme(),
        locale: Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
          const Locale("en_US"),
          const Locale("ja_JP")
        ],
      ),
    );
  }

  ThemeData _generateTheme() {
    var baseTheme = ThemeData(
      brightness: Brightness.dark,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      dividerColor: Colors.grey[800],
      popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
      primaryColor: Color(0xff2e3533),
      scaffoldBackgroundColor: Color(0xff1b1f1e),
      appBarTheme: AppBarTheme(color: Color(0xff1b1f1e), elevation: 0),
      accentColor: Color(0xff45c17c),
      cursorColor: Color(0xff45c17c),
      textSelectionColor: Color(0xff2d8052),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
      ),
      cupertinoOverrideTheme:
          CupertinoThemeData(primaryColor: Color(0xff45c17c)),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          contentTextStyle: TextStyle(color: Colors.black87)),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Color(0xff1b1f1e)),
      }),
    );

    return baseTheme;
  }
}
