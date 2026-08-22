import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_cubit.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/repository/smiley_pack_repository.dart';
import 'package:hkgalden_flutter/ui/startup_screen.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';
import 'package:hkgalden_flutter/utils/thread_reading_position_store.dart';
import 'dart:io';
import 'package:flutter_displaymode/flutter_displaymode.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {
    }
  }

  await Hive.initFlutter();
  await Hive.openBox('token');
  await Hive.openBox(ThreadReadingPositionStore.boxName);
  await Hive.openBox(ImageAspectRatioStore.boxName);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => HKGaldenApi()),
        RepositoryProvider(
            create: (context) => SmileyPackRepository(
                api: RepositoryProvider.of<HKGaldenApi>(context))),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) => ChannelCubit(
                  api: RepositoryProvider.of<HKGaldenApi>(context))),
          BlocProvider(
              create: (context) => SessionUserCubit(
                  api: RepositoryProvider.of<HKGaldenApi>(context))),
          BlocProvider(
              create: (context) => ThreadListCubit(
                  api: RepositoryProvider.of<HKGaldenApi>(context)))
        ],
        child: MaterialApp(
          home: StartupScreen(),
          color: const Color(0xff1b1f1e),
          theme: AppTheme.generate(context),
          locale: const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
          localizationsDelegates: const [
            FlutterQuillLocalizations.delegate,
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
      ),
    );
  }
}
