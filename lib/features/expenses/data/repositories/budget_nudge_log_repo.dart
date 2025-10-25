import 'package:hive/hive.dart';

import '../models/budget_nudge_log.dart';

class BudgetNudgeLogRepository {
  BudgetNudgeLogRepository(this._box);

  final Box<BudgetNudgeLog> _box;

  List<BudgetNudgeLog> listRecent({int limit = 25}) {
    final items = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  List<BudgetNudgeLog> listForMonth(DateTime month, {int limit = 50}) {
    final normalized = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final items = _box.values.where((log) {
      return !log.createdAt.isBefore(normalized) && log.createdAt.isBefore(end);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  Future<void> add(BudgetNudgeLog log) async {
    await _box.put(log.id, log);
  }
}
