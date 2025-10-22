import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/expense.dart';
import '../../data/models/category.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final categoriesBox = Hive.box<Category>('categories');
    final cat = categoriesBox.values.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => Category(
        id: 'other',
        name: 'Other',
        color: 0xFF90A4AE,
        emoji: '✨',
      ),
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(cat.color),
        child: Text(
          cat.emoji.isNotEmpty ? cat.emoji : '💵',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      title: Text('${cat.name} • ${formatMinor(expense.amountMinor)}'),
      subtitle: Text(
        expense.note.isEmpty
            ? formatDate(expense.date)
            : '${formatDate(expense.date)} — ${expense.note}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Use push so the user can naturally go back (gesture / system back)
      onTap: () => context.push('/edit/${expense.id}'),
    );
  }
}
