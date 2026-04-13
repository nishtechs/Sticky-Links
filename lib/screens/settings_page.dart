import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../providers/settings_provider.dart';
import '../providers/links_provider.dart';
import '../models/link_item.dart';
import '../widgets/window_buttons.dart';
import '../services/backup_service.dart';
import '../services/bookmark_service.dart';
import '../services/permission_service.dart';
import 'whats_new_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _exportData(BuildContext context) async {
    final linksProvider = Provider.of<LinksProvider>(context, listen: false);
    List<LinkItem> all = linksProvider.allLinks;
    final jsonList = all.map((link) => link.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/sticky_links_backup.json');
        await file.writeAsString(jsonString);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Sticky Links Backup',
          text: 'Here is your Sticky Links backup file.',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
        }
      }
    } else {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Links to File', 
        fileName: 'sticky_links_backup.json', 
        type: FileType.custom, 
        allowedExtensions: ['json']
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export successful!')));
        }
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      try {
        final List<dynamic> jsonList = jsonDecode(content);
        if (!context.mounted) return;
        final linksProvider = Provider.of<LinksProvider>(context, listen: false);

        final importedLinks = jsonList.map((item) => LinkItem.fromJson(item)).toList();
        final importResult = await linksProvider.importLinks(importedLinks);
        final added = importResult['added'] ?? 0;
        final updated = importResult['updated'] ?? 0;

        if (context.mounted) {
          String message = 'Import complete! Added $added new links.';
          if (updated > 0) message += ' Updated $updated existing categories.';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse import file format.')));
        }
      }
    }
  }

  Future<void> _importBookmarks(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['html', 'htm']);

    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      try {
        final List<LinkItem> importedLinks = BookmarkService.parseBookmarkHtml(content);
        if (!context.mounted) return;
        final linksProvider = Provider.of<LinksProvider>(context, listen: false);

        final importResult = await linksProvider.importLinks(importedLinks);
        final added = importResult['added'] ?? 0;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import complete! Added $added new links from bookmarks.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse bookmark file.')));
        }
      }
    }
  }

  Future<void> _pickBackupPath(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    final hasPermission = await PermissionService.requestStoragePermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission required to change backup folder.')));
      }
      return;
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Custom Backup Folder');

    if (selectedDirectory != null) {
      await settings.setCustomBackupPath(selectedDirectory);
      BackupService.updateScheduler();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = Provider.of<SettingsProvider>(context);

    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return Scaffold(
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight + appWindow.titleBarHeight),
              child: Column(
                children: [
                  WindowTitleBarBox(
                    child: Row(
                      children: [
                        Expanded(child: MoveWindow()),
                        const CustomWindowButtons(),
                      ],
                    ),
                  ),
                  AppBar(primary: false, title: const Text('Settings'), centerTitle: true),
                ],
              ),
            )
          : AppBar(title: const Text('Settings'), centerTitle: true),
      body: isDesktop ? _buildSettingsList(context, colorScheme, settings) : SafeArea(child: _buildSettingsList(context, colorScheme, settings)),
    );
  }

  Widget _buildSettingsList(BuildContext context, ColorScheme colorScheme, SettingsProvider settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Display Settings
        _buildSectionHeader('Display', Icons.display_settings_rounded, colorScheme),
        const SizedBox(height: 12),
        _buildSettingsCard(
          colorScheme: colorScheme,
          children: [

            _buildSwitchTile(icon: Icons.dark_mode_rounded, title: 'Dark Mode', subtitle: 'Use dark theme', value: settings.isDarkMode, onChanged: (value) => settings.toggleDarkMode(value), colorScheme: colorScheme),
            const Divider(height: 1),
            _buildSwitchTile(icon: Icons.blur_on_rounded, title: 'Glassmorphism', subtitle: 'Enable frosted glass effects', value: settings.isGlassEnabled, onChanged: (value) => settings.toggleGlassEnabled(value), colorScheme: colorScheme),
            // const Divider(height: 1),

            _buildSwitchTile(icon: Icons.animation_rounded, title: 'Dynamic Background', subtitle: 'Animated mesh gradient background', value: settings.isDynamicBackgroundEnabled, onChanged: (value) => settings.toggleDynamicBackground(value), colorScheme: colorScheme),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.palette_rounded, color: colorScheme.onPrimaryContainer, size: 20),
                      ),
                      const SizedBox(width: 16),
                      const Text('Theme Color', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ColorOption(color: const Color(0xFF6366F1), label: 'Indigo'),
                      _ColorOption(color: const Color(0xFFEF4444), label: 'Red'),
                      _ColorOption(color: const Color(0xFF10B981), label: 'Emerald'),
                      _ColorOption(color: const Color(0xFFF59E0B), label: 'Amber'),
                      _ColorOption(color: const Color(0xFF3B82F6), label: 'Blue'),
                      _ColorOption(color: const Color(0xFF8B5CF6), label: 'Violet'),
                      _ColorOption(color: const Color(0xFFEC4899), label: 'Pink'),
                      _ColorOption(color: const Color(0xFF06B6D4), label: 'Cyan'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Data Management
        _buildSectionHeader('Data', Icons.storage_rounded, colorScheme),
        const SizedBox(height: 12),
        _buildSettingsCard(
          colorScheme: colorScheme,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.download_rounded, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              title: const Text('Export Data'),
              subtitle: const Text('Save your links to a file'),
              onTap: () => _exportData(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.upload_rounded, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              title: const Text('Import Data'),
              subtitle: const Text('Load links from a file'),
              onTap: () => _importData(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.bookmark_added_rounded, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              title: const Text('Import Bookmarks'),
              subtitle: const Text('Import from Chrome/Firefox HTML'),
              onTap: () => _importBookmarks(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.access_time_filled_rounded, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              title: const Text('Auto Backup Interval'),
              subtitle: const Text('Frequency of background backups'),
              trailing: DropdownButton<int>(
                value: settings.backupIntervalHours,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Off')),
                  DropdownMenuItem(value: 1, child: Text('Every 1 Hour')),
                  DropdownMenuItem(value: 12, child: Text('Every 12 Hours')),
                  DropdownMenuItem(value: 24, child: Text('Every 24 Hours')),
                ],
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    settings.setBackupInterval(newValue);
                    BackupService.updateScheduler();
                  }
                },
              ),
            ),
            const Divider(height: 1),
            FutureBuilder<String>(
              future: BackupService.getResolvedBackupPath(),
              builder: (context, snapshot) {
                final pathText = snapshot.data ?? 'Loading...';
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.folder_open_rounded, color: colorScheme.onPrimaryContainer, size: 20),
                  ),
                  title: const Text('Backup Location'),
                  subtitle: Text(pathText, style: TextStyle(fontSize: 12)),
                  trailing: TextButton(onPressed: () => _pickBackupPath(context), child: const Text('Change')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.history_rounded, color: colorScheme.onPrimaryContainer, size: 20),
              ),
              title: const Text('Last Backup'),
              subtitle: Text(
                settings.lastBackupTime == null
                    ? 'Never'
                    : '${settings.lastBackupTime!.day}/${settings.lastBackupTime!.month}/${settings.lastBackupTime!.year} at '
                          '${settings.lastBackupTime!.hour.toString().padLeft(2, '0')}:${settings.lastBackupTime!.minute.toString().padLeft(2, '0')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Backup Now',
                onPressed: () async {
                  try {
                    await BackupService.triggerManualBackup();
                    if (context.mounted) {
                      settings.refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup successful!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Backup failed: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // About Section
        _buildSectionHeader('About', Icons.info_rounded, colorScheme),
        const SizedBox(height: 12),
        _buildSettingsCard(
          colorScheme: colorScheme,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.link_rounded, color: colorScheme.onPrimaryContainer),
              ),
              title: const Text('Sticky Links'),
              subtitle: const Text('Version 2.2.0'),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, _, _) => const WhatsNewPage(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary, letterSpacing: 0.5),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required ColorScheme colorScheme, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged, required ColorScheme colorScheme}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: colorScheme.outline)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorOption({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isSelected = settings.themeColor.toARGB32() == color.toARGB32();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => settings.setThemeColor(color),
      child: Tooltip(
        message: label,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: isSelected ? colorScheme.onSurface : Colors.transparent, width: 2),
            boxShadow: [if (isSelected) BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)],
          ),
          child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
        ),
      ),
    );
  }
}
