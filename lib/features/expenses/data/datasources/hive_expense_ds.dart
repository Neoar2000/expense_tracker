import 'package:hive/hive.dart';
import '../models/expense.dart';

class HiveExpenseDataSource {
  final Box<Expense> expensesBox;
  HiveExpenseDataSource(this.expensesBox);

  List<Expense> getAll() =>
      expensesBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  Future<void> add(Expense e) => expensesBox.add(e);
  Future<void> deleteAt(int index) => expensesBox.deleteAt(index);

  Future<void> deleteById(String id) async {
    final key = expensesBox.keys.firstWhere((k) {
      final value = expensesBox.get(k);
      return value?.id == id;
    }, orElse: () => null);

    if (key != null) {
      await expensesBox.delete(key);
    }
  }

  Future<void> update(String id, Expense updated) async {
    final key = expensesBox.keys.firstWhere((k) {
      final value = expensesBox.get(k);
      return value?.id == id;
    }, orElse: () => null);

    if (key != null) {
      await expensesBox.put(key, updated);
    }
  }
}
