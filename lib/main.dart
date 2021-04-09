import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/ui/startup_screen.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance!.resamplingEnabled = true;
  await Hive.initFlutter();
  await Hive.openBox('token');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ChannelBloc()),
        BlocProvider(create: (context) => SessionUserBloc()),
        BlocProvider(create: (context) => ThreadBloc()),
        BlocProvider(create: (context) => ThreadListBloc())
      ],
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
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              primary: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)))),
      dividerColor: Colors.grey[800],
      primaryColor: const Color(0xff2e3533),
      canvasColor: const Color(0xff1b1f1e),
      scaffoldBackgroundColor: const Color(0xff1b1f1e),
      appBarTheme: const AppBarTheme(color: Color(0xff1b1f1e), elevation: 0),
      accentColor: const Color(0xff45c17c),
      textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xff45c17c), selectionColor: Color(0xff2d8052)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        focusElevation: 1,
        highlightElevation: 1,
        foregroundColor: Colors.white,
      ),
      cupertinoOverrideTheme:
          const CupertinoThemeData(primaryColor: Color(0xff45c17c)),
    );
    return baseTheme;
  }
}
