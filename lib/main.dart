import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'features/spy_game/presentation/spy_home_screen.dart';
import 'features/spy_game/presentation/theme/app_theme.dart';
import 'firebase_options.dart';

/// Your OneSignal app id, passed on the command line:
///   flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id
/// When it is empty, push notifications are simply not set up and the game
/// still works.
const String _oneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (_oneSignalAppId.isNotEmpty) {
    await OneSignal.initialize(_oneSignalAppId);
  }

  runApp(const ProviderScope(child: SpyGameApp()));
}

class SpyGameApp extends StatelessWidget {
  const SpyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مَن الجاسوس؟',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // The game's texts are Arabic, so the app runs in Arabic (right to left).
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SpyHomeScreen(),
    );
  }
}
