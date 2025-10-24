import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/models/category.dart';
import '../../data/models/default_categories.dart';

final categoriesBoxProvider = Provider<Box<Category>>((ref) {
  return Hive.box<Category>('categories');
});

final allCategoriesProvider = Provider<List<Category>>((ref) {
  final box = ref.watch(categoriesBoxProvider);
  final stored = box.values.toList();
  final existingIds = stored.map((c) => c.id).toSet();

  final merged = [...stored];
  for (final cat in defaultCategories()) {
    if (!existingIds.contains(cat.id)) {
      merged.add(cat);
    }
  }

  merged.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return merged;
});
