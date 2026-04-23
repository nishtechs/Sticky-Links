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

  @HiveField(7)
  final bool isArchived;

  @HiveField(8)
  final int clickCount;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final String? previewImageUrl;

  LinkItem({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.faviconUrl,
    this.category,
    this.previewImageUrl,
    bool? isArchived,
    int? clickCount,
    List<String>? tags,
    int? timestamp,
  }) : isArchived = isArchived ?? false,
       clickCount = clickCount ?? 0,
       tags = tags ?? const [],
       timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'faviconUrl': faviconUrl,
      'category': category,
      'previewImageUrl': previewImageUrl,
      'timestamp': timestamp,
      'isArchived': isArchived,
      'clickCount': clickCount,
      'tags': tags,
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
      previewImageUrl: json['previewImageUrl'] as String?,
      timestamp: json['timestamp'] as int?,
      isArchived: json['isArchived'] as bool? ?? false,
      clickCount: json['clickCount'] as int? ?? 0,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
