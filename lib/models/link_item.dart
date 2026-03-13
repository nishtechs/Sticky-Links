import 'package:hive/hive.dart';

part 'link_item.g.dart';

@HiveType(typeId: 0)
class LinkItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String? faviconUrl;

  @HiveField(5)
  final String? category;

  @HiveField(6)
  final int timestamp;

  LinkItem({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.faviconUrl,
    this.category,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'faviconUrl': faviconUrl,
      'category': category,
      'timestamp': timestamp,
    };
  }

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      id: json['id'].toString(),
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      category: json['category'] as String?,
      timestamp: json['timestamp'] as int?,
    );
  }
}
