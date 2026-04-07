import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  bool get isGridView => StorageService.isGridView;
  bool get isDarkMode => StorageService.isDarkMode;
  int get backupIntervalHours => StorageService.backupIntervalHours;
  String? get customBackupPath => StorageService.customBackupPath;
  DateTime? get lastBackupTime => StorageService.lastBackupTime;
  bool get isGlassEnabled => StorageService.isGlassEnabled;
  bool get isDynamicBackgroundEnabled => StorageService.isDynamicBackgroundEnabled;

  Future<void> toggleGridView(bool value) async {
    await StorageService.setGridView(value);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    await StorageService.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setBackupInterval(int hours) async {
    await StorageService.setBackupIntervalHours(hours);
    notifyListeners();
  }

  Future<void> setCustomBackupPath(String? path) async {
    await StorageService.setCustomBackupPath(path);
    notifyListeners();
  }

  Color get themeColor => Color(StorageService.themeColorValue);

  Future<void> setThemeColor(Color color) async {
    await StorageService.setThemeColorValue(color.toARGB32());
    notifyListeners();
  }

  Future<void> toggleGlassEnabled(bool value) async {
    await StorageService.setGlassEnabled(value);
    notifyListeners();
  }

  Future<void> toggleDynamicBackground(bool value) async {
    await StorageService.setDynamicBackgroundEnabled(value);
    notifyListeners();
  }

  bool get isWhatsNewSeen => StorageService.isWhatsNewSeen;

  Future<void> markWhatsNewSeen() async {
    await StorageService.setWhatsNewSeen(true);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
