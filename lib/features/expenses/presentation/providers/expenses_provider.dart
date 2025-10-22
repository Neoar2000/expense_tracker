import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/expense.dart';
import '../../data/repositories/expense_repo.dart';

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
}

final expensesProvider =
    NotifierProvider<ExpensesController, List<Expense>>(ExpensesController.new);
