import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:showcaseview/showcaseview.dart';

import 'services/storage_service.dart';
import 'services/backup_service.dart';
import 'providers/settings_provider.dart';
import 'providers/links_provider.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local DB and settings
  await StorageService.init();

  // Start the background backup scheduler
  BackupService.startScheduler();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LinksProvider()),
      ],
      child: const StickyLinksApp(),
    ),
  );

  doWhenWindowReady(() {
    const initialSize = Size(1000, 700);
    appWindow.minSize = const Size(600, 400);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "Sticky Links";
    appWindow.show();
  });
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
      home: ShowCaseWidget(
        builder: (context) => const StickyLinksHomePage(),
      ),
    );
  }
}