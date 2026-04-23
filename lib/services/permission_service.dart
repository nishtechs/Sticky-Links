import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // NOTE: This app does NOT use or request Location permissions on any platform.
  // Location access reported by Windows may be a side-effect of certain plugin
  // initializations (like device_info_plus or share_plus) but is not utilized
  // by the application logic.

  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 11+ (API 30+)
      if (androidInfo.version.sdkInt >= 30) {
        // For Android 11+, we ideally use Scoped Storage or app internal.
        // If the user wants to write to public folders, they technically need MANAGE_EXTERNAL_STORAGE
        // but that's high-risk for Play Store.
        // We'll check regular storage first, and maybe request manageExternalStorage if absolutely needed.
        var status = await Permission.storage.request();
        if (status.isGranted) return true;

        // If storage is denied, check if maybe they need manageExternalStorage
        // (Usually only for specific path requirements)
        if (await Permission.manageExternalStorage.isRestricted) {
          return false;
        }

        status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        // Android < 11
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // On iOS, permissions are handled differently, but generally 'storage' is not an explicit permission
      // needed for writing to the app's sandbox. Files picked via picker are usually granted access via UTI.
      return true;
    }

    return true;
  }

  static Future<bool> checkPermissionStatus() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;
        return (await Permission.storage.status).isGranted;
      } else {
        return (await Permission.storage.status).isGranted;
      }
    }

    return true;
  }
}
