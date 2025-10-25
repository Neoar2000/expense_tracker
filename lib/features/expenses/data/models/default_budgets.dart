import 'category.dart';
import 'category_budget.dart';

const _defaultBudgetMap = <String, int>{
  'food': 40000,
  'transport': 12000,
  'housing': 85000,
  'groceries': 50000,
  'travel': 30000,
  'shopping': 25000,
  'health': 20000,
  'entertainment': 18000,
  'other': 15000,
};

List<CategoryBudget> defaultBudgetsForMonth(
  Iterable<Category> categories,
  DateTime month,
) {
  final normalized = DateTime(month.year, month.month, 1);
  return categories
      .map(
        (cat) => CategoryBudget.forMonth(
          categoryId: cat.id,
          month: normalized,
          limitMinor: _defaultBudgetMap[cat.id] ?? 20000,
          warningThreshold: 0.85,
          pushNudgesEnabled: true,
          emailNudgesEnabled: cat.id != 'entertainment',
        ),
      )
      .toList();
}
