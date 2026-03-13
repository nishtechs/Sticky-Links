import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class CategoryItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue;

  CategoryItem({
    required this.id,
    required this.name,
    required this.colorValue,
  });
}
