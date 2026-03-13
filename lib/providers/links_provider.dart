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
  String _sortOrder = 'newest'; // newest, oldest, alphabetical

  List<LinkItem> get allLinks => _links;

  List<String> _categories = ['All'];
  List<String> get categories => _categories;

  List<LinkItem> get links {
    List<LinkItem> filtered = _links.where((link) {
      bool matchesSearch = _searchQuery.isEmpty ||
          link.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          link.url.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (link.description != null && link.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      bool matchesCategory = _selectedCategory == null || _selectedCategory == 'All' || link.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();

    if (_sortOrder == 'newest') {
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (_sortOrder == 'oldest') {
      filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (_sortOrder == 'alphabetical') {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
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

  Future<void> addCategory(String name) async {
    if (name.isNotEmpty && !_categories.contains(name)) {
      final newCat = CategoryItem(id: const Uuid().v4(), name: name, colorValue: Colors.blue.value);
      await StorageService.addCategory(newCat);
      _categories.add(name);
      notifyListeners();
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
    notifyListeners();
    BackupService.triggerManualBackup();
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
}
