import 'package:hive/hive.dart';

import '../models/category_budget.dart';

class CategoryBudgetRepository {
  CategoryBudgetRepository(Box<CategoryBudget> box) : _box = box;

  final Box<CategoryBudget> _box;

  List<CategoryBudget> list() => _box.values.toList();

  List<CategoryBudget> listForMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month, 1);
    return _box.values
        .where(
          (b) => b.year == normalized.year && b.month == normalized.month,
        )
        .toList();
  }

  Future<void> upsert(CategoryBudget budget) async {
    await _box.put(budget.id, budget);
  }

  Future<void> markAlert({
    required CategoryBudget budget,
    required int alertLevel,
  }) async {
    await _box.put(
      budget.id,
      budget.copyWith(
        lastAlertLevel: alertLevel,
        lastAlertAt: DateTime.now(),
      ),
    );
  }

  bool exists(String id) => _box.containsKey(id);
}
