import 'package:hive_flutter/hive_flutter.dart';
import '../models/link_item.dart';
import '../models/category.dart';

class StorageService {
  static const String _linksBoxName = 'links_box';
  static const String _categoriesBoxName = 'categories_box';
  static const String _settingsBoxName = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(LinkItemAdapter());
    Hive.registerAdapter(CategoryItemAdapter());

    await Hive.openBox<LinkItem>(_linksBoxName);
    await Hive.openBox<CategoryItem>(_categoriesBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // Links
  static Box<LinkItem> get linksBox => Hive.box<LinkItem>(_linksBoxName);
  
  static List<LinkItem> getLinks() {
    return linksBox.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> addLink(LinkItem link) async {
    await linksBox.put(link.id, link);
  }

  static Future<void> removeLink(String id) async {
    await linksBox.delete(id);
  }

  // Categories
  static Box<CategoryItem> get categoriesBox => Hive.box<CategoryItem>(_categoriesBoxName);

  static List<CategoryItem> getCategories() {
    return categoriesBox.values.toList();
  }

  static Future<void> addCategory(CategoryItem category) async {
    await categoriesBox.put(category.id, category);
  }
  
  static Future<void> removeCategory(String id) async {
    await categoriesBox.delete(id);
  }

  // Settings
  static Box get settingsBox => Hive.box(_settingsBoxName);

  static bool get isGridView => settingsBox.get('isGridView', defaultValue: false);
  static Future<void> setGridView(bool value) async => await settingsBox.put('isGridView', value);

  static bool get isDarkMode => settingsBox.get('isDarkMode', defaultValue: false);
  static Future<void> setDarkMode(bool value) async => await settingsBox.put('isDarkMode', value);

  static int get backupIntervalHours => settingsBox.get('backupIntervalHours', defaultValue: 1);
  static Future<void> setBackupIntervalHours(int value) async => await settingsBox.put('backupIntervalHours', value);

  static String? get customBackupPath => settingsBox.get('customBackupPath');
  static Future<void> setCustomBackupPath(String? value) async {
    if (value == null) {
      await settingsBox.delete('customBackupPath');
    } else {
      await settingsBox.put('customBackupPath', value);
    }
  }

  static bool get hasShownTutorial => settingsBox.get('hasShownTutorial', defaultValue: false);
  static Future<void> setHasShownTutorial(bool value) async => await settingsBox.put('hasShownTutorial', value);
}
