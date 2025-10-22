import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/expense.dart';
import '../providers/expenses_provider.dart';
import 'filters_provider.dart';

// --- Models for derived stats ---
class CategoryTotal {
  final String categoryId;
  final int totalMinor;
  CategoryTotal(this.categoryId, this.totalMinor);
}

class TrendPoint {
  final DateTime day;
  final int totalMinor;
  TrendPoint(this.day, this.totalMinor);
}

class MonthStats {
  final int totalMinor;
  final int count;
  final List<CategoryTotal> byCategory;
  final List<TrendPoint> dailyTrend;
  const MonthStats({
    required this.totalMinor,
    required this.count,
    required this.byCategory,
    required this.dailyTrend,
  });
}

/// Helper: first day of month
DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);
DateTime _monthEndExclusive(DateTime d) =>
    DateTime(d.year, d.month + 1, 1); // exclusive upper bound

MonthStats computeMonthStats(List<Expense> all, DateTime month) {
  final start = _monthStart(month);
  final endEx = _monthEndExclusive(month);

  // Filter this month
  final monthItems = all
      .where((e) => !e.date.isBefore(start) && e.date.isBefore(endEx))
      .toList();

  // Totals
  final totalMinor = monthItems.fold<int>(0, (sum, e) => sum + e.amountMinor);
  final count = monthItems.length;

  // By category
  final byCatMap = <String, int>{};
  for (final e in monthItems) {
    byCatMap.update(e.categoryId, (v) => v + e.amountMinor,
        ifAbsent: () => e.amountMinor);
  }
  final byCategory = byCatMap.entries
      .map((e) => CategoryTotal(e.key, e.value))
      .toList()
    ..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));

  // Daily trend
  final days = <DateTime, int>{};
  var cursor = start;
  while (cursor.isBefore(endEx)) {
    days[cursor] = 0;
    cursor = cursor.add(const Duration(days: 1));
  }
  for (final e in monthItems) {
    final dayKey = DateTime(e.date.year, e.date.month, e.date.day);
    days.update(dayKey, (v) => v + e.amountMinor,
        ifAbsent: () => e.amountMinor);
  }
  final dailyTrend = days.entries
      .map((e) => TrendPoint(e.key, e.value))
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));

  return MonthStats(
    totalMinor: totalMinor,
    count: count,
    byCategory: byCategory,
    dailyTrend: dailyTrend,
  );
}

final monthStatsProvider = Provider<MonthStats>((ref) {
  final expenses = ref.watch(expensesProvider);
  final selected = ref.watch(filtersProvider).month;
  return computeMonthStats(expenses, selected);
});
