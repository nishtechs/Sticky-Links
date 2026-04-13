import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:showcaseview/showcaseview.dart';

import '../models/link_item.dart';
import '../providers/links_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/link_card.dart';
import '../widgets/grid_link_card.dart';
import '../widgets/window_buttons.dart';
import '../services/storage_service.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'settings_page.dart';
import '../services/metadata_service.dart';
import '../widgets/dynamic_background.dart';
import '../widgets/glass_container.dart';
import 'dart:async';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:share_handler/share_handler.dart';
import 'whats_new_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StickyLinksHomePage extends StatefulWidget {
  const StickyLinksHomePage({super.key});

  @override
  State<StickyLinksHomePage> createState() => _StickyLinksHomePageState();
}

class _StickyLinksHomePageState extends State<StickyLinksHomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final GlobalKey _addKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _categoryScrollController = ScrollController();

  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // Set up receiving intents (shared links from other apps)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final handler = ShareHandler.instance;
      
      // For sharing or opening URLs/text coming from outside the app while the app is in the memory
      _intentDataStreamSubscription = handler.sharedMediaStream.listen((SharedMedia media) {
        if (media.content != null) {
           _handleSharedText(media.content!);
        } else if (media.attachments != null && media.attachments!.isNotEmpty) {
           final attachmentPath = media.attachments!.first?.path;
           if (attachmentPath != null) {
              _handleSharedFile(attachmentPath);
           }
        }
      }, onError: (err) {
        debugPrint("sharedMediaStream error: $err");
      });

      // For sharing or opening URLs/text coming from outside the app while the app is closed
      handler.getInitialSharedMedia().then((SharedMedia? media) {
        if (media != null) {
          if (media.content != null) {
            _handleSharedText(media.content!);
          } else if (media.attachments != null && media.attachments!.isNotEmpty) {
             final attachmentPath = media.attachments!.first?.path;
             if (attachmentPath != null) {
                _handleSharedFile(attachmentPath);
             }
          }
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LinksProvider>().loadLinks();
      final settings = context.read<SettingsProvider>();
      
      if (!settings.isWhatsNewSeen) {
         Navigator.of(context).push(
           PageRouteBuilder(
             pageBuilder: (context, _, _) => const WhatsNewPage(),
             transitionsBuilder: (context, animation, secondaryAnimation, child) {
               return FadeTransition(opacity: animation, child: child);
             },
             transitionDuration: const Duration(milliseconds: 600),
           ),
         );
      } else if (!StorageService.hasShownTutorial) {
        ShowcaseView.get().startShowCase([_addKey, _searchKey, _settingsKey]);
        StorageService.setHasShownTutorial(true);
      }
    });
  }

  Future<void> _handleSharedText(String text) async {
    // Basic validation to see if it's a URL
    String cleanUrl = text.trim();
    if (!cleanUrl.startsWith('http')) {
      // In case they just shared text like "example.com", try prepending https
      cleanUrl = 'https://$cleanUrl';
    }
    
    // We try to fetch metadata right away to pre-fill the form
    final meta = await MetadataService.fetchMetadata(cleanUrl);
    
    if (mounted) {
      _showLinkBottomSheet(initialUrl: cleanUrl, initialTitle: meta['title']);
    }
  }

  Future<void> _handleSharedFile(String path) async {
    if (!path.toLowerCase().endsWith('.json')) {
       _showIncompatibleFileDialog();
       return;
    }

    try {
      final file = File(path);
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      if (data is List) {
         _showImportFileDialog(data);
      } else {
         _showIncompatibleFileDialog();
      }
    } catch (e) {
      debugPrint("Error handling shared file: $e");
      _showIncompatibleFileDialog();
    }
  }

  void _showIncompatibleFileDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Incompatible File'),
          ],
        ),
        content: const Text('This JSON file is not compatible with Sticky Links.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImportFileDialog(List<dynamic> jsonList) {
     if (!mounted) return;
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
         title: const Text('Import Links'),
         content: Text('Found ${jsonList.length} links in this file. Would you like to import them into your collection?'),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancel'),
           ),
           FilledButton(
             onPressed: () async {
               Navigator.pop(context);
               final provider = context.read<LinksProvider>();
               int count = 0;
               for (var item in jsonList) {
                 try {
                   final link = LinkItem.fromJson(item as Map<String, dynamic>);
                   await provider.addLink(link);
                   count++;
                 } catch (_) {}
               }
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Successfully imported $count links!'),
                     behavior: SnackBarBehavior.floating,
                   ),
                 );
               }
             },
             child: const Text('Import All'),
           ),
         ],
       ),
     );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    _searchFocusNode.dispose();
    _categoryScrollController.dispose();
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  Future<String?> _fetchFaviconUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      final String baseUrl = '${uri.scheme}://${uri.host}';

      List<String> faviconPaths = [
        '/favicon.ico',
        '/favicon.png',
        '/apple-touch-icon.png',
        '/icon.png',
      ];

      for (String path in faviconPaths) {
        final String faviconUrl = '$baseUrl$path';
        try {
          final response = await http.get(Uri.parse(faviconUrl));
          if (response.statusCode == 200) {
            return faviconUrl;
          }
        } catch (e) {
          // Continue to next path
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  String? _selectedDialogCategory;
  // Local list to keep track of categories for dropdowns within dialogs
  List<String> get _categories => context.read<LinksProvider>().categories;

  void _showAddCategoryDialog(StateSetter updateParentDialog) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: 'Category Name', filled: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (catController.text.trim().isNotEmpty) {
                 final newCat = catController.text.trim();
                  context.read<LinksProvider>().addCategory(newCat);
                  updateParentDialog(() {
                    _selectedDialogCategory = newCat;
                  });
              }
              Navigator.pop(context);
              // Refresh the main dialog state to reflect new category
              if (mounted) setState(() {});
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _showCategoryContextMenu(BuildContext context, Offset position, String category, ColorScheme colorScheme) async {
    if (category == 'All') return; // Cannot edit/delete 'All'
    
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Rename Category'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download_rounded, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 12),
              const Text('Export Category Links'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 20, color: colorScheme.error),
              const SizedBox(width: 12),
              Text('Delete Category', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ],
    );

    if (result == 'edit') {
      if (mounted) _showRenameCategoryDialog(category);
    } else if (result == 'export') {
      if (mounted) _exportCategoryLinks(category);
    } else if (result == 'delete') {
      if (mounted) _showDeleteCategoryDialog(category);
    }
  }

  Future<void> _exportCategoryLinks(String category) async {
    final linksProvider = Provider.of<LinksProvider>(context, listen: false);
    final categoryLinks = linksProvider.allLinks.where((l) => l.category == category).toList();

    if (categoryLinks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No links found in category "$category" to export.')),
        );
      }
      return;
    }

    final jsonList = categoryLinks.map((link) => link.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final directory = await getTemporaryDirectory();
        final fileName = 'links_${category.toLowerCase().replaceAll(' ', '_')}.json';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Sticky Links: $category',
          text: 'Here are my saved links for "$category".',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
        }
      }
    } else {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export "$category" Links',
        fileName: 'links_${category.toLowerCase().replaceAll(' ', '_')}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported ${categoryLinks.length} links from "$category"!')),
          );
        }
      }
    }
  }

  void _showRenameCategoryDialog(String oldName) {
    final catController = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: 'New Category Name', filled: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final newCat = catController.text.trim();
              if (newCat.isNotEmpty && newCat != oldName) {
                context.read<LinksProvider>().updateCategory(oldName, newCat);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$categoryName"?\n\nLinks inside this category will not be deleted, they will just lose the category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<LinksProvider>().removeCategory(categoryName);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLinkBottomSheet({LinkItem? existingLink, String? initialUrl, String? initialTitle}) {
    bool isEditing = existingLink != null;
    
    _selectedDialogCategory = existingLink?.category;

    List<String> dialogTags = existingLink?.tags != null ? List<String>.from(existingLink!.tags) : [];
    final tagController = TextEditingController();
    bool isFetching = false;
    String? currentPreviewUrl = existingLink?.previewImageUrl;

    if (isEditing) {
      _titleController.text = existingLink.title;
      _urlController.text = existingLink.url;
      _descriptionController.text = existingLink.description ?? '';
    } else {
      _titleController.text = initialTitle ?? '';
      _urlController.text = initialUrl ?? '';
      _descriptionController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateLocal) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle area
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isEditing ? Icons.edit_rounded : Icons.add_link_rounded,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEditing ? 'Edit Link' : 'Add New Link',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    labelText: 'Link Title',
                                    hintText: 'Enter a name for this link',
                                    prefixIcon: const Icon(Icons.title_rounded),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter a title';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Stack(
                                  alignment: Alignment.centerRight,
                                  children: [
                                    TextFormField(
                                      controller: _urlController,
                                      decoration: InputDecoration(
                                        labelText: 'URL',
                                        hintText: 'Enter website URL',
                                        prefixIcon: const Icon(Icons.link_rounded),
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.only(right: 100, left: 12, top: 12, bottom: 12),
                                      ),
                                      keyboardType: TextInputType.url,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter a URL';
                                        }
                                        return null;
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: isFetching 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : TextButton.icon(
                                          onPressed: () async {
                                             String url = _urlController.text.trim();
                                             if (url.isEmpty) return;
                                             setStateLocal(() => isFetching = true);
                                             final meta = await MetadataService.fetchMetadata(url);
                                             setStateLocal(() {
                                               if (meta['title'] != null && _titleController.text.isEmpty) {
                                                 _titleController.text = meta['title']!;
                                               }
                                               if (meta['description'] != null && _descriptionController.text.isEmpty) {
                                                 _descriptionController.text = meta['description']!;
                                               }
                                               currentPreviewUrl = meta['previewImageUrl'];
                                               isFetching = false;
                                             });
                                          }, 
                                          icon: const Icon(Icons.auto_awesome, size: 16),
                                          label: const Text('Fetch'),
                                          style: TextButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                          ),
                                        ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: InputDecoration(
                                    labelText: 'Description (Optional)',
                                    hintText: 'Add a description for this link',
                                    prefixIcon: const Icon(Icons.description_rounded),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _categories.contains(_selectedDialogCategory) ? _selectedDialogCategory : 'All',
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    prefixIcon: const Icon(Icons.category_rounded),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: [
                                    ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                                    const DropdownMenuItem(value: '__NEW__', child: Text('+ Add New Category...', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  onChanged: (value) {
                                    if (value == '__NEW__') {
                                      _showAddCategoryDialog(setStateLocal);
                                    } else {
                                      setStateLocal(() {
                                        _selectedDialogCategory = value == 'All' ? null : value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Tagging UI
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: tagController,
                                      decoration: InputDecoration(
                                        labelText: 'Add Tags',
                                        hintText: 'Press Enter to add tag',
                                        prefixIcon: const Icon(Icons.label_outline_rounded),
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onFieldSubmitted: (value) {
                                        if (value.trim().isNotEmpty && !dialogTags.contains(value.trim())) {
                                          setStateLocal(() {
                                            dialogTags.add(value.trim());
                                            tagController.clear();
                                          });
                                        }
                                      },
                                    ),
                                    if (dialogTags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: dialogTags.map((tag) => Chip(
                                          label: Text(tag, style: const TextStyle(fontSize: 12)),
                                          onDeleted: () {
                                            setStateLocal(() => dialogTags.remove(tag));
                                          },
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        )).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: () => _saveLink(
                            existingLink: existingLink, 
                            tags: dialogTags,
                            previewUrl: currentPreviewUrl,
                          ),
                          icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                          label: Text(isEditing ? 'Save Changes' : 'Add Link'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveLink({LinkItem? existingLink, List<String>? tags, String? previewUrl}) async {
    if (_formKey.currentState!.validate()) {
      String fullUrl = _urlController.text.trim();

      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        fullUrl = 'https://$fullUrl';
      }

      String? faviconUrl = existingLink?.faviconUrl;
      String? currentPreviewUrl = previewUrl ?? existingLink?.previewImageUrl;

      if (existingLink == null || existingLink.url != fullUrl) {
         final meta = await MetadataService.fetchMetadata(fullUrl);
         if (!mounted) return;
         faviconUrl = meta['faviconUrl'] ?? await _fetchFaviconUrl(fullUrl);
         if (!mounted) return;
         currentPreviewUrl = previewUrl ?? meta['previewImageUrl'];
      }

      if (!mounted) return;
      final provider = context.read<LinksProvider>();

      if (existingLink == null) {
         if (provider.isDuplicate(fullUrl)) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Duplicate Link'),
                content: const Text('This link is already in your list. Do you want to add it again?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Add Anyway')),
                ],
              ),
            );
            if (confirm != true) return;
         }
        
        final newLink = LinkItem(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          url: fullUrl,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          faviconUrl: faviconUrl,
          category: _selectedDialogCategory,
          tags: tags ?? [],
          previewImageUrl: currentPreviewUrl,
        );
        await provider.addLink(newLink);
      } else {
        final updatedLink = LinkItem(
          id: existingLink.id,
          title: _titleController.text.trim(),
          url: fullUrl,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          faviconUrl: faviconUrl,
          category: _selectedDialogCategory ?? existingLink.category,
          timestamp: existingLink.timestamp,
          tags: tags ?? existingLink.tags,
          previewImageUrl: currentPreviewUrl,
        );
        await provider.updateLink(updatedLink);
      }

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingLink == null ? 'Link added successfully!' : 'Link updated!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _openLink(String url) async {
    final provider = context.read<LinksProvider>();
    final link = provider.allLinks.firstWhere((l) => l.url == url, orElse: () => throw 'Link not found');
    provider.incrementClick(link.id);

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to close Sticky Links?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final linksProvider = context.watch<LinksProvider>();

    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit && context.mounted) {
           SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
                  _buildAppBar(context, colorScheme, settings, linksProvider, isDesktop: true),
                ],
              ),
            )
          : _buildAppBar(context, colorScheme, settings, linksProvider, isDesktop: false),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => _searchFocusNode.requestFocus(),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _showLinkBottomSheet(),
          const SingleActivator(LogicalKeyboardKey.keyH, control: true): () => linksProvider.toggleShowArchived(),
          const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => settings.toggleGridView(!settings.isGridView),
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (linksProvider.selectedIds.isNotEmpty) {
              linksProvider.clearSelection();
            } else {
              linksProvider.setSearchQuery('');
              _searchFocusNode.unfocus();
            }
          },
        },
        child: isDesktop 
            ? DropTarget(
                onDragDone: (details) async {
                  final provider = context.read<LinksProvider>();
                  for (final file in details.files) {
                     final path = file.path;
                     if (path.startsWith('http')) {
                        final meta = await MetadataService.fetchMetadata(path);
                        final newLink = LinkItem(
                          id: const Uuid().v4(),
                          title: meta['title'] ?? path,
                          url: path,
                          description: meta['description'],
                          faviconUrl: meta['faviconUrl'],
                          previewImageUrl: meta['previewImageUrl'],
                          category: linksProvider.selectedCategory == 'All' ? null : linksProvider.selectedCategory,
                        );
                        await provider.addLink(newLink);
                     }
                  }
                },
                child: _buildHomeBody(context, colorScheme, settings, linksProvider, isDesktop),
              )
            : SafeArea(
                child: _buildHomeBody(context, colorScheme, settings, linksProvider, isDesktop),
              ),
      ),
      bottomNavigationBar: linksProvider.selectedIds.isNotEmpty
          ? _buildBulkActionBar(colorScheme, linksProvider)
          : null,
      floatingActionButton: linksProvider.selectedIds.isNotEmpty ? null : Showcase(
        key: _addKey,
        title: 'Add New Link',
        description: 'Click here to save and organize your links.',
        child: FloatingActionButton.extended(
          onPressed: () => _showLinkBottomSheet(),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Link',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ColorScheme colorScheme, SettingsProvider settings, LinksProvider linksProvider, {required bool isDesktop}) {
    return AppBar(
      primary: !isDesktop,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'app_logo.png',
              width: 20,
              height: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sticky Links',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        // View toggle
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(12),
            isSelected: [!settings.isGridView, settings.isGridView],
            onPressed: (index) {
              settings.toggleGridView(index == 1);
            },
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            children: const [
              Icon(Icons.view_list_rounded, size: 20),
              Icon(Icons.grid_view_rounded, size: 20),
            ],
          ),
        ),
        IconButton(
          icon: Icon(linksProvider.showArchived ? Icons.archive_rounded : Icons.unarchive_rounded),
          onPressed: linksProvider.toggleShowArchived,
          tooltip: linksProvider.showArchived ? 'Show Active' : 'Show Archived',
        ),
        Showcase(
          key: _settingsKey,
          title: 'Settings',
          description: 'Access backups, theme settings, import/export data here.',
          child: IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: _openSettings,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHomeBody(BuildContext context, ColorScheme colorScheme, SettingsProvider settings, LinksProvider linksProvider, bool isDesktop) {
    final links = linksProvider.links;
    return DynamicBackground(
      isEnabled: settings.isDynamicBackgroundEnabled,
      seedColor: settings.themeColor,
      child: Column(
        children: [
          // Search Bar
          Showcase(
            key: _searchKey,
            title: 'Search & Filter',
            description: 'Find your saved links easily, and filter by categories below.',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GlassContainer(
                isEnabled: settings.isGlassEnabled,
                opacity: 0.05,
                child: TextField(
                  focusNode: _searchFocusNode,
                  onChanged: linksProvider.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: isDesktop ? 'Search links... (Ctrl+F)' : 'Search links...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: linksProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              linksProvider.setSearchQuery('');
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: settings.isGlassEnabled ? 0.3 : 0.8),
                  ),
                ),
              ),
            ),
          ),
          // Category Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                controller: _categoryScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: linksProvider.categories.length,
                itemBuilder: (context, index) {
                  final cat = linksProvider.categories[index];
                  final isSelected = linksProvider.selectedCategory == cat;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => linksProvider.setCategory(cat),
                      onSecondaryTapDown: (details) => _showCategoryContextMenu(context, details.globalPosition, cat, colorScheme),
                      onLongPressStart: (details) => _showCategoryContextMenu(context, details.globalPosition, cat, colorScheme),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: isSelected 
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withBlue(200).withGreen(150),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                          color: !isSelected 
                            ? (isSelected 
                                ? colorScheme.primaryContainer.withValues(alpha: 0.4) 
                                : colorScheme.surfaceContainerHighest.withValues(alpha: settings.isGlassEnabled ? 0.3 : 0.8))
                            : null,
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ] : [],
                          border: Border.all(
                            color: isSelected 
                              ? colorScheme.primary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (cat == 'All') ...[
                                Icon(
                                  Icons.grid_view_rounded, 
                                  size: 16, 
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Links Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text(
                  'Your Links',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${links.length}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: linksProvider.sortOrder,
                  icon: const Icon(Icons.sort_rounded, size: 20),
                  underline: const SizedBox(),
                  onChanged: (String? value) {
                    if (value != null) linksProvider.setSortOrder(value);
                  },
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                    DropdownMenuItem(value: 'alphabetical', child: Text('A-Z')),
                    DropdownMenuItem(value: 'most_clicked', child: Text('Most Clicked')),
                  ],
                ),
              ],
            ),
          ),
          // Links List/Grid
          Expanded(
            child: linksProvider.totalLinks == 0 && linksProvider.searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.link_off_rounded,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No links yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first link!',
                          style: TextStyle(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : links.isEmpty
                    ? Center(child: Text('No results for "${linksProvider.searchQuery}"'))
                    : settings.isGridView
                        ? _buildGridView(colorScheme, links, linksProvider)
                        : _buildListView(colorScheme, links, linksProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(ColorScheme colorScheme, LinksProvider provider) {
    final isNarrow = MediaQuery.of(context).size.width < 500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 24, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              isNarrow ? '${provider.selectedIds.length}' : '${provider.selectedIds.length} selected',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const Spacer(),
            if (isNarrow) ...[
               IconButton(
                 onPressed: () => provider.bulkArchive(!provider.showArchived),
                 icon: Icon(provider.showArchived ? Icons.unarchive_rounded : Icons.archive_rounded),
                 tooltip: provider.showArchived ? 'Unarchive' : 'Archive',
               ),
               IconButton(
                 onPressed: () => _showBulkDeleteDialog(provider),
                 icon: const Icon(Icons.delete_outline_rounded),
                 color: colorScheme.error,
                 tooltip: 'Delete',
               ),
            ] else ...[
              TextButton.icon(
                onPressed: () => provider.bulkArchive(!provider.showArchived),
                icon: Icon(provider.showArchived ? Icons.unarchive_rounded : Icons.archive_rounded),
                label: Text(provider.showArchived ? 'Unarchive' : 'Archive'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showBulkDeleteDialog(provider),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              ),
            ],
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => provider.clearSelection(),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear Selection',
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkDeleteDialog(LinksProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete'),
        content: Text('Delete ${provider.selectedIds.length} selected links?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.bulkDelete();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(ColorScheme colorScheme, List<LinkItem> links, LinksProvider provider) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: links.length,
        itemBuilder: (context, index) {
          final link = links[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LinkCard(
                    link: link,
                    onTap: () => _openLink(link.url),
                    onEdit: () => _showLinkBottomSheet(existingLink: link),
                    onDelete: () => provider.removeLink(link.id),
                    onArchive: () => provider.archiveLink(link.id, !link.isArchived),
                    isSelected: provider.selectedIds.contains(link.id),
                    onLongPress: () => provider.toggleSelection(link.id),
                    colorScheme: colorScheme,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridView(ColorScheme colorScheme, List<LinkItem> links, LinksProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double itemWidth = 220.0;
        const double itemHeight = 220.0;
        const double crossAxisSpacing = 12.0;

        int crossAxisCount = (constraints.maxWidth / (itemWidth + crossAxisSpacing)).floor();
        crossAxisCount = crossAxisCount.clamp(2, 6);

        return AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: crossAxisSpacing,
              childAspectRatio: itemWidth / itemHeight,
              mainAxisExtent: itemHeight,
            ),
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 375),
                columnCount: crossAxisCount,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: GridLinkCard(
                      link: link,
                      onTap: () => _openLink(link.url),
                      onEdit: () => _showLinkBottomSheet(existingLink: link),
                     onDelete: () => provider.removeLink(link.id),
                     onArchive: () => provider.archiveLink(link.id, !link.isArchived),
                     isSelected: provider.selectedIds.contains(link.id),
                     onLongPress: () => provider.toggleSelection(link.id),
                     colorScheme: colorScheme,
                   ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
