import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/services.dart';

import 'services/storage_service.dart';
import 'services/backup_service.dart';
import 'services/server_service.dart';
import 'providers/settings_provider.dart';
import 'providers/links_provider.dart';
import 'screens/home_page.dart';
import 'models/shortcuts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local DB and settings
  await StorageService.init();

  final linksProvider = LinksProvider();
  final settingsProvider = SettingsProvider();

  // Start the background backup scheduler
  BackupService.startScheduler();

  // Start local server for external communication (Desktop only)
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    ServerService.start(linksProvider);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: linksProvider),
      ],
      child: const StickyLinksApp(),
    ),
  );

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    doWhenWindowReady(() {
      const initialSize = Size(1100, 750);
      appWindow.minSize = const Size(600, 400);
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = "Sticky Links";
      appWindow.show();
    });
  }
}

class StickyLinksApp extends StatelessWidget {
  const StickyLinksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Sticky Links',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.themeColor,
          brightness: Brightness.light,
        ),
        fontFamily: 'Segoe UI',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.themeColor,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Segoe UI',
      ),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ShowCaseWidget(builder: (context) => const StickyLinksHomePage()),
    );
  }
}
