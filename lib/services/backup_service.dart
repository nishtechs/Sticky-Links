import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:sticky_links/services/storage_service.dart';
import 'package:sticky_links/services/permission_service.dart';

class BackupService {
  static Timer? _timer;

  /// Starts a periodic scheduler to automatically backup links
  static void startScheduler() {
    _timer?.cancel();
    
    final int hours = StorageService.backupIntervalHours;
    if (hours <= 0) return; // '0' means backup is disabled

    // Run an initial backup immediately
    triggerManualBackup();

    // Schedule periodic backups
    _timer = Timer.periodic(Duration(hours: hours), (timer) {
      triggerManualBackup();
    });
  }

  static void updateScheduler() {
    // Just restart the scheduler with the latest interval from StorageService
    startScheduler();
  }

  static void stopScheduler() {
    _timer?.cancel();
  }

  static Future<String> getResolvedBackupPath() async {
    final customPath = StorageService.customBackupPath;
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'sticky_links');
  }

  static Future<void> triggerManualBackup() async {
    try {
      // Request permissions before proceeding
      final hasPermission = await PermissionService.requestStoragePermission();
      if (!hasPermission) {
        throw 'Storage permission denied. Backup cannot proceed.';
      }

      final targetPath = await getResolvedBackupPath();
      final targetDirectory = Directory(targetPath);
      
      if (!await targetDirectory.exists()) {
        try {
          await targetDirectory.create(recursive: true);
        } catch (e) {
          throw 'Permission denied to create backup directory: $targetPath';
        }
      }

      final links = StorageService.getLinks();
      final jsonList = links.map((link) => link.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      final file = File(p.join(targetDirectory.path, 'backup.json'));
      try {
        await file.writeAsString(jsonString);
      } catch (e) {
        throw 'Permission denied to write backup file: ${file.path}';
      }

      await StorageService.setLastBackupTime(DateTime.now());
      debugPrint('Automated backup successful: ${file.path}');
    } catch (e) {
      debugPrint('Failed to perform automated backup: $e');
      rethrow;
    }
  }
}
