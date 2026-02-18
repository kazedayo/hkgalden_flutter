import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/repository/channel_repository.dart';
import 'package:hkgalden_flutter/repository/session_user_repository.dart';
import 'package:hkgalden_flutter/repository/thread_list_repository.dart';
import 'package:hkgalden_flutter/ui/startup_screen.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('token');
  await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => ChannelRepository()),
        RepositoryProvider(create: (context) => SessionUserRepository()),
        RepositoryProvider(create: (context) => ThreadListRepository())
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) => ChannelBloc(
                  repository:
                      RepositoryProvider.of<ChannelRepository>(context))),
          BlocProvider(
              create: (context) => SessionUserBloc(
                  repository:
                      RepositoryProvider.of<SessionUserRepository>(context))),
          BlocProvider(
              create: (context) => ThreadListBloc(
                  repository:
                      RepositoryProvider.of<ThreadListRepository>(context)))
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
