import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  bool get isGridView => StorageService.isGridView;
  bool get isDarkMode => StorageService.isDarkMode;
  int get backupIntervalHours => StorageService.backupIntervalHours;
  String? get customBackupPath => StorageService.customBackupPath;

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
}
