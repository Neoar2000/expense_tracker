import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repo.dart';
import 'filters_provider.dart';

final expensesBoxProvider = Provider<Box<Expense>>((ref) {
  return Hive.box<Expense>('expenses');
});

final expensesRepoProvider = Provider<ExpenseRepository>((ref) {
  final box = ref.watch(expensesBoxProvider);
  return ExpenseRepository(box);
});

class ExpensesController extends Notifier<List<Expense>> {
  late final ExpenseRepository _repo;

  @override
  List<Expense> build() {
    _repo = ref.read(expensesRepoProvider);
    return _repo.list();
  }

  void refresh() => state = _repo.list();

  Future<void> add(Expense e) async {
    await _repo.add(e);
    refresh();
  }

  Future<void> update(Expense e) async {
    await _repo.update(e);
    refresh();
  }

  Future<void> deleteAt(int index) async {
    await _repo.deleteAt(index);
    refresh();
  }

  Future<void> deleteById(String id) async {
    await _repo.deleteById(id);
    refresh();
  }
}

final expensesProvider =
    NotifierProvider<ExpensesController, List<Expense>>(ExpensesController.new);

List<Expense> _applyFilters(List<Expense> expenses, FilterState filters) {
  Iterable<Expense> result = expenses;

  final query = filters.query.trim().toLowerCase();
  if (query.isNotEmpty) {
    result = result.where(
      (e) => e.note.toLowerCase().contains(query) || e.id.toLowerCase().contains(query),
    );
  }

  final categoryId = filters.categoryId;
  if (categoryId != null && categoryId.isNotEmpty) {
    result = result.where((e) => e.categoryId == categoryId);
  }

  final range = filters.dateRange;
  if (range != null) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    result = result.where((e) {
      final date = e.date;
      return !date.isBefore(start) && !date.isAfter(end);
    });
  }

  return result.toList();
}

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final filters = ref.watch(filtersProvider);
  return _applyFilters(expenses, filters);
});
