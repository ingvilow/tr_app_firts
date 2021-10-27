// @dart=2.9

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_app/models/RouteWithStops.dart';
import 'package:fl_app/models/Routes.dart';
import 'package:fl_app/screens/FavoritesPage.dart';
import 'package:fl_app/screens/HomeSceen.dart';
import 'package:fl_app/screens/MapPage.dart';
import 'package:fl_app/screens/NotifScreen.dart';
import 'package:fl_app/screens/SearchPage.dart';

import 'package:fl_app/service/ChangingTheme.dart';
import 'package:fl_app/service/TransportService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'l10n/l10n.dart';
import 'models/MarshrutVariant.dart';
import 'models/StopsForMap.dart';

/*Короче, Бедолага, даю тебе код и в благородство играть не буду:
* уберешь для меня пару костылей и мы в расчете.
* Заодно посмотрим как быстро твоя башка варит в работе с легаси.
* А по твоей теме попытаюсь разузнать.
* Хрен его знает, на кой ляд тебе эта работа в БР сдалась,
* но я в чужие дела не лезу, хочешь работать здесь, значит, есть за что*/

///Receive message when app is in background solution for on message
Future<void> backgroundHandler(RemoteMessage message) async {
  print(message.data.toString());
  print(message.notification.title);
}

const favoritesBox = 'favorite';
const favorBox = 'favsStop';
final getIt = GetIt.asNewInstance();

Future<void> main() async {
  getIt.registerSingleton(TransportService());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  Hive.registerAdapter(RouteWithStopsAdapter());
  Hive.registerAdapter(StopAdapter());
  Hive.registerAdapter(RoutesAdapter());
  Hive.registerAdapter(ScheduleVariantsAdapter());
  await Hive.initFlutter();
  await Hive.openBox<RouteWithStops>(favoritesBox);
  await Hive.openBox<Stop>(favorBox);
  return runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DarkThemeProvider themeChangeProvider = new DarkThemeProvider();

  @override
  void initState() {
    super.initState();
    getCurrentAppTheme();
  }

  void getCurrentAppTheme() async {
    themeChangeProvider.darkTheme =
        await themeChangeProvider.darkThemePreference.getTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create: (_) {
      return themeChangeProvider;
    }, child: Consumer<DarkThemeProvider>(
        builder: (BuildContext context, value, Widget child) {
      return MaterialApp(
        theme: Styles.themeData(themeChangeProvider.darkTheme, context),
        debugShowCheckedModeBanner: false,
        home: Homescreen(),
        routes: {
          'favorite': (_) => FavsSavePage(),
          'favsStop': (_) => FavoriteStops()
        },
        supportedLocales: L10n.all,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
      );
    }));
  }
}