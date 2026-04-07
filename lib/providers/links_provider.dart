import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/link_item.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';

class LinksProvider with ChangeNotifier {
  List<LinkItem> _links = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortOrder = 'newest'; // newest, oldest, alphabetical, most_clicked
  bool _showArchived = false;
  final List<String> _selectedIds = [];

  List<LinkItem> get allLinks => _links;
  bool get showArchived => _showArchived;
  List<String> get selectedIds => _selectedIds;

  List<String> _categories = ['All'];
  List<String> get categories => _categories;

  List<LinkItem> get links {
    List<LinkItem> filtered = _links.where((link) {
      bool matchesSearch = _searchQuery.isEmpty ||
          link.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          link.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (link.description != null && link.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      bool matchesCategory = _selectedCategory == null || _selectedCategory == 'All' || link.category == _selectedCategory;
      
      bool matchesArchive = link.isArchived == _showArchived;
      
      return matchesSearch && matchesCategory && matchesArchive;
    }).toList();

    if (_sortOrder == 'newest') {
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (_sortOrder == 'oldest') {
      filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (_sortOrder == 'alphabetical') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else if (_sortOrder == 'most_clicked') {
      filtered.sort((a, b) => b.clickCount.compareTo(a.clickCount));
    }

    return filtered;
  }

  int get totalLinks => _links.length;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String get sortOrder => _sortOrder;

  Future<void> loadLinks() async {
    _links = StorageService.getLinks();
    var cats = StorageService.getCategories();
    _categories = ['All', ...cats.map((c) => c.name)];
    notifyListeners();
  }

  bool isDuplicate(String url) {
    String normalizedUrl = url.trim().toLowerCase();
    if (!normalizedUrl.endsWith('/')) normalizedUrl += '/';
    return _links.any((l) {
      String lUrl = l.url.toLowerCase();
      if (!lUrl.endsWith('/')) lUrl += '/';
      return lUrl == normalizedUrl;
    });
  }

  Future<void> addCategory(String name, {bool notify = true}) async {
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty && !_categories.contains(trimmedName)) {
      final newCat = CategoryItem(id: const Uuid().v4(), name: trimmedName, colorValue: Colors.blue.toARGB32());
      await StorageService.addCategory(newCat);
      _categories.add(trimmedName);
      if (notify) notifyListeners();
    }
  }

  Future<void> updateCategory(String oldName, String newName) async {
    if (newName.isNotEmpty && oldName != newName && !_categories.contains(newName)) {
      var cats = StorageService.getCategories();
      try {
        var catToUpdate = cats.firstWhere((c) => c.name == oldName);
        var updatedCat = CategoryItem(id: catToUpdate.id, name: newName, colorValue: catToUpdate.colorValue);
        await StorageService.addCategory(updatedCat);
        
        // Update all links with this category
        for (var link in _links.where((l) => l.category == oldName)) {
          final updatedLink = LinkItem(
            id: link.id,
            title: link.title,
            url: link.url,
            description: link.description,
            faviconUrl: link.faviconUrl,
            category: newName,
            timestamp: link.timestamp,
            tags: link.tags,
            previewImageUrl: link.previewImageUrl,
            isArchived: link.isArchived,
            clickCount: link.clickCount,
          );
           await StorageService.addLink(updatedLink);
        }

        // reload links and categories
        await loadLinks();
      } catch(e) { /* ignore */ }
    }
  }

  Future<void> removeCategory(String name) async {
    var cats = StorageService.getCategories();
    try {
      var catToRemove = cats.firstWhere((c) => c.name == name);
      await StorageService.removeCategory(catToRemove.id);
      
      // Clear category from existing links
      for (var link in _links.where((l) => l.category == name)) {
         final updatedLink = LinkItem(
           id: link.id,
           title: link.title,
           url: link.url,
           description: link.description,
           faviconUrl: link.faviconUrl,
           category: null, // Clear the category
           timestamp: link.timestamp,
         );
         await StorageService.addLink(updatedLink);
      }
      
      if (_selectedCategory == name) _selectedCategory = null;
      
      await loadLinks();
    } catch(e) { /* ignore */ }
  }

  Future<void> addLink(LinkItem link) async {
    await StorageService.addLink(link);
    _links.add(link);
    notifyListeners();
    BackupService.triggerManualBackup();
  }

  Future<void> updateLink(LinkItem updatedLink) async {
    await StorageService.addLink(updatedLink); // Hive put overwrites existing
    int index = _links.indexWhere((l) => l.id == updatedLink.id);
    if (index != -1) {
      _links[index] = updatedLink;
      notifyListeners();
      BackupService.triggerManualBackup();
    }
  }

  Future<void> removeLink(String id) async {
    await StorageService.removeLink(id);
    _links.removeWhere((link) => link.id == id);
    _selectedIds.remove(id);
    notifyListeners();
    BackupService.triggerManualBackup();
  }

  Future<void> archiveLink(String id, bool archive) async {
    int index = _links.indexWhere((l) => l.id == id);
    if (index != -1) {
      final old = _links[index];
      final updated = LinkItem(
        id: old.id,
        title: old.title,
        url: old.url,
        description: old.description,
        faviconUrl: old.faviconUrl,
        category: old.category,
        timestamp: old.timestamp,
        isArchived: archive,
        clickCount: old.clickCount,
        tags: old.tags,
        previewImageUrl: old.previewImageUrl,
      );
      await StorageService.addLink(updated);
      _links[index] = updated;
      notifyListeners();
      BackupService.triggerManualBackup();
    }
  }

  Future<void> moveLinkToCategory(String id, String? newCategory) async {
    int index = _links.indexWhere((l) => l.id == id);
    if (index != -1) {
      final old = _links[index];
      final updated = LinkItem(
        id: old.id,
        title: old.title,
        url: old.url,
        description: old.description,
        faviconUrl: old.faviconUrl,
        category: newCategory,
        timestamp: old.timestamp,
        isArchived: old.isArchived,
        clickCount: old.clickCount,
        tags: old.tags,
        previewImageUrl: old.previewImageUrl,
      );
      await StorageService.addLink(updated);
      _links[index] = updated;
      notifyListeners();
      BackupService.triggerManualBackup();
    }
  }

  Future<void> incrementClick(String id) async {
    int index = _links.indexWhere((l) => l.id == id);
    if (index != -1) {
      final old = _links[index];
      final updated = LinkItem(
        id: old.id,
        title: old.title,
        url: old.url,
        description: old.description,
        faviconUrl: old.faviconUrl,
        category: old.category,
        timestamp: old.timestamp,
        isArchived: old.isArchived,
        clickCount: old.clickCount + 1,
        tags: old.tags,
        previewImageUrl: old.previewImageUrl,
      );
      await StorageService.addLink(updated);
      _links[index] = updated;
      notifyListeners();
    }
  }

  // Bulk Operations
  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> bulkDelete() async {
    for (var id in _selectedIds) {
      await StorageService.removeLink(id);
      _links.removeWhere((l) => l.id == id);
    }
    _selectedIds.clear();
    notifyListeners();
    BackupService.triggerManualBackup();
  }

  Future<void> bulkArchive(bool archive) async {
    for (var id in _selectedIds) {
       await archiveLink(id, archive);
    }
    _selectedIds.clear();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortOrder(String order) {
    _sortOrder = order;
    notifyListeners();
  }

  void toggleShowArchived() {
    _showArchived = !_showArchived;
    _selectedIds.clear();
    notifyListeners();
  }
  Future<Map<String, int>> importLinks(List<LinkItem> newLinks) async {
    int added = 0;
    int updated = 0;

    // 1. Ensure all categories from the backup exist (case-insensitive)
    for (var link in newLinks) {
      final rawCat = link.category?.trim();
      if (rawCat != null && rawCat.isNotEmpty && rawCat != 'All') {
        bool exists = _categories.any((c) => c.toLowerCase() == rawCat.toLowerCase());
        if (!exists) {
          await addCategory(rawCat, notify: false);
        }
      }
    }

    // 2. Prepare for link importing
    Map<String, LinkItem> currentLinksByUrl = {
      for (var l in _links) _normalizeUrl(l.url): l
    };

    for (var link in newLinks) {
      String normalizedUrl = _normalizeUrl(link.url);
      
      // Match category name to the exact casing in our system
      String? matchedCategory;
      if (link.category != null) {
        final trimmed = link.category!.trim();
        matchedCategory = _categories.firstWhere(
          (c) => c.toLowerCase() == trimmed.toLowerCase(), 
          orElse: () => trimmed
        );
        if (matchedCategory == 'All') matchedCategory = null;
      }

      if (!currentLinksByUrl.containsKey(normalizedUrl)) {
        // New link
        final linkToAdd = LinkItem(
          id: const Uuid().v4(),
          title: link.title,
          url: link.url,
          description: link.description,
          faviconUrl: link.faviconUrl,
          category: matchedCategory,
          timestamp: link.timestamp,
          isArchived: link.isArchived,
          clickCount: link.clickCount,
          tags: link.tags,
        );

        await StorageService.addLink(linkToAdd);
        _links.add(linkToAdd);
        currentLinksByUrl[normalizedUrl] = linkToAdd;
        added++;
      } else {
        // Existing link - update category if it's different in the backup
        final existing = currentLinksByUrl[normalizedUrl]!;
        if (existing.category != matchedCategory) {
          final updatedLink = LinkItem(
            id: existing.id,
            title: existing.title,
            url: existing.url,
            description: existing.description,
            faviconUrl: existing.faviconUrl,
            category: matchedCategory, // Use the one from the backup
            timestamp: existing.timestamp,
            isArchived: existing.isArchived,
            clickCount: existing.clickCount,
            tags: existing.tags,
          );
          await StorageService.addLink(updatedLink);
          int index = _links.indexWhere((l) => l.id == existing.id);
          if (index != -1) _links[index] = updatedLink;
          updated++;
        }
      }
    }

    if (added > 0 || updated > 0) {
      notifyListeners();
      BackupService.triggerManualBackup();
    }
    return {'added': added, 'updated': updated};
  }

  String _normalizeUrl(String url) {
    String normalized = url.trim().toLowerCase();
    if (!normalized.endsWith('/')) normalized += '/';
    return normalized;
  }
}
