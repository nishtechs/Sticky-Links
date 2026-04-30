class PermissionService {
  // NOTE: This app does NOT use or request Location permissions on any platform.
  // Location access reported by Windows may be a side-effect of certain plugin
  // initializations (like device_info_plus or share_plus) but is not utilized
  // by the application logic.

  static Future<bool> requestStoragePermission() async {
    return true;
  }

  static Future<bool> checkPermissionStatus() async {
    return true;
  }
}
