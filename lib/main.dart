import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:eduapge2/api.dart';
import 'package:eduapge2/home.dart';
import 'package:eduapge2/load.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:eduapge2/l10n/app_localizations.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  await remoteConfig.setDefaults(const {
    "baseUrl": "https://lobster-app-z6jfk.ondigitalocean.app/api",
    "testUrl": "https://ep2.vypal.me"
  });
  await remoteConfig.fetchAndActivate();
  await SentryFlutter.init(
    (options) {
      options.dsn = kDebugMode
          ? ''
          : 'https://9c458db0f7204c84946c2d8ca59556ed@o4504950085976064.ingest.sentry.io/4504950092136448';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(const MyApp()),
  );
  //OneSignal.shared.setAppId("85587dc6-0a3c-4e91-afd6-e0ca82361763");
  //OneSignal.shared.promptUserForPushNotificationPermission();
}

abstract class BaseState<T extends StatefulWidget> extends State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  ColorScheme _generateColorScheme(Color? primaryColor,
      [Brightness? brightness]) {
    final Color seedColor = primaryColor ?? Colors.blue;

    final ColorScheme newScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness ?? Brightness.light,
    );

    return newScheme.harmonized();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return ToastificationWrapper(
        child: MaterialApp(
          title: 'EduPage2',
          navigatorKey: navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [SentryNavigatorObserver(), observer],
          theme: ThemeData(
            colorScheme: _generateColorScheme(
              lightColorScheme?.primary,
              Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: _generateColorScheme(
              darkColorScheme?.primary,
              Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: ThemeMode.dark,
          home: const PageBase(),
          routes: <String, WidgetBuilder>{
            '/home': (BuildContext context) => Home(context: context),
          },
        ),
      );
    });
  }
}

class PageBase extends StatefulWidget {
  const PageBase({super.key});

  @override
  BaseState<PageBase> createState() => PageBaseState();
}

class PageBaseState extends BaseState<PageBase> {
  String baseUrl = FirebaseRemoteConfig.instance.getString("testUrl");

  bool loaded = false;

  bool error = false; //for error status
  bool loading = false; //for data featching status
  String errmsg = ""; //to assing any error message from API/runtime
  List<TimelineItem> apidataMsg = [];
  bool refresh = true;
  bool iCanteenEnabled = false;
  bool _isCheckingForUpdate = false;
  final ShorebirdUpdater _shorebirdCodePush = ShorebirdUpdater();

  SessionManager sessionManager = SessionManager();

  @override
  void initState() {
    setOptimalDisplayMode();
    if (!_isCheckingForUpdate) _checkForUpdate(); // ik that it's not necessary
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution = supported
        .where((DisplayMode m) =>
            m.width == active.width && m.height == active.height)
        .toList()
      ..sort((DisplayMode a, DisplayMode b) =>
          b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;

    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    // Ask the Shorebird servers if there is a new patch available.
    final isUpdateAvailable = await _shorebirdCodePush.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _isCheckingForUpdate = false;
    });

    if (isUpdateAvailable == UpdateStatus.outdated) {
      _downloadUpdate();
    }
  }

  void _showDownloadingBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      const MaterialBanner(
        content: Text('Downloading patch...'),
        actions: [
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        ],
      ),
    );
  }

  void _showRestartBanner() {
    ScaffoldMessenger.of(context).showMaterialBanner(
      const MaterialBanner(
        content: Text('A new patch is ready!'),
        actions: [
          TextButton(
            // Restart the app for the new patch to take effect.
            onPressed: Restart.restartApp,
            child: Text('Restart app'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUpdate() async {
    _showDownloadingBanner();
    await _shorebirdCodePush.update();
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    _showRestartBanner();
  }

  getMsgs() async {
    apidataMsg = EP2Data.getInstance().timeline.items.values.toList();
    dynamic ic = await sessionManager.get('iCanteenEnabled');
    if (ic.runtimeType == bool && ic == true) {
      iCanteenEnabled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: Load(context: context),
    );
  }
}
