import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/adaptive_dialog.dart';
import '../../data/models/expense.dart';
import '../providers/expenses_provider.dart';
import '../widgets/expense_tile.dart';

class ExpensesListPage extends ConsumerWidget {
  const ExpensesListPage({super.key});

  Future<bool> _confirmDelete(BuildContext context) async {
    return AdaptiveDialog.confirm(
      context,
      title: 'Delete expense?',
      message: 'This action cannot be undone.',
      okText: 'Delete',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final controller = ref.read(expensesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // native back
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'), // keep push so back works
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: expenses.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final Expense e = expenses[index];

                return Dismissible(
                  key: ValueKey(e.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),

                  // confirm before deleting (adaptive)
                  confirmDismiss: (_) => _confirmDelete(context),

                  // delete after animation
                  onDismissed: (_) async {
                    await controller.deleteAt(index);
                    // SnackBar is fine; on iOS we injected a ScaffoldMessenger in main.dart
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted expense #${e.id.substring(0, 6)}',
                        ),
                      ),
                    );
                  },

                  // tile inside a Card keeps animation stable
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ExpenseTile(expense: e),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No expenses yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Tap the + button to add your first expense.'),
            const SizedBox(height: 20),

            // You can keep this Material button or switch to AdaptiveButton if you prefer.
            FilledButton.icon(
              onPressed: () => context.push('/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
