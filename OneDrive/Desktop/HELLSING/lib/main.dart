
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'database/hive_database.dart';
import 'screens/splash_screen.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for notifications
  tz.initializeTimeZones();

  // Lock to portrait on mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFFCB1E1E),
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF0A0000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await YamadaDatabase.init();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request notification permissions (non-blocking)
  notificationService.requestPermissions();

  // Initialize background tasks (Android/iOS only)
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await BackgroundService.initialize();
  }

  final themeProvider = ThemeProvider();

  runApp(
    MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const YamadaApp(),
    ),
  );
}

class YamadaApp extends StatelessWidget {
  const YamadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'YAMADA',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: const SplashScreen(),
        );
      },
    );
  }
}
