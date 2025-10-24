import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../datasources/hive_expense_ds.dart';

class ExpenseRepository {
  final HiveExpenseDataSource _ds;
  ExpenseRepository(Box<Expense> box) : _ds = HiveExpenseDataSource(box);

  List<Expense> list() => _ds.getAll();
  Future<void> add(Expense e) => _ds.add(e);
  Future<void> update(Expense e) => _ds.update(e.id, e);
  Future<void> deleteAt(int index) => _ds.deleteAt(index);
  Future<void> deleteById(String id) => _ds.deleteById(id);
}
