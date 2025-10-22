import 'package:hive/hive.dart';
part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final int color; // ARGB int
  @HiveField(3)
  final String emoji;

  Category({
    required this.id,
    required this.name,
    required this.color,
    this.emoji = '',
  });
}
