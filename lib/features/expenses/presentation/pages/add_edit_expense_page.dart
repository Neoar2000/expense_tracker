import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/adaptive_dialog.dart';
import '../../../../core/widgets/adaptive_button.dart';

import '../../data/models/expense.dart';
import '../../data/models/category.dart';
import '../providers/expenses_provider.dart';

class AddEditExpensePage extends ConsumerStatefulWidget {
  final String? expenseId; // null = add, non-null = edit
  const AddEditExpensePage({super.key, this.expenseId});

  @override
  ConsumerState<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends ConsumerState<AddEditExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;

  Expense? _original; // when editing

  @override
  void initState() {
    super.initState();
    // If editing, fetch the expense and prefill
    if (widget.expenseId != null) {
      final all = ref.read(expensesProvider);
      // Routing ensures id exists; guard anyway
      try {
        _original = all.firstWhere((e) => e.id == widget.expenseId);
      } catch (_) {
        _original = null;
      }

      if (_original != null) {
        _amountController.text = (_original!.amountMinor / 100.0)
            .toStringAsFixed(2);
        _noteController.text = _original!.note;
        _selectedDate = _original!.date;

        final catBox = Hive.box<Category>('categories');
        _selectedCategory = catBox.values.firstWhere(
          (c) => c.id == _original!.categoryId,
          orElse: () => Category(
            id: 'other',
            name: 'Other',
            color: 0xFF90A4AE,
            emoji: '✨',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(expensesProvider.notifier);
    final categoriesBox = Hive.box<Category>('categories');
    final categories = categoriesBox.values.toList();

    final isEdit = widget.expenseId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/'); // fallback if opened directly
            }
          },
        ),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await AdaptiveDialog.confirm(
                  context,
                  title: 'Delete expense?',
                  message: 'This action cannot be undone.',
                  okText: 'Delete',
                );
                if (!confirmed) return;

                // Find index of the original item in provider state
                final list = ref.read(expensesProvider);
                final idx = list.indexWhere((e) => e.id == _original!.id);
                if (idx != -1) {
                  await controller.deleteAt(idx);
                  if (mounted) {
                    // Works on iOS too; ScaffoldMessenger is injected in main.dart builder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense deleted')),
                    );
                    if (context.canPop()) {
                      context.pop(); // go back to previous page
                    } else {
                      context.go('/'); // fallback
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (USD)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter an amount';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${formatDate(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<Category>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Text(c.emoji.isNotEmpty ? '${c.emoji} ' : ''),
                            Text(c.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Actions (adaptive)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AdaptiveButton(
                    label: 'Cancel',
                    style: AdaptiveButtonStyle.text,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  AdaptiveButton(
                    label: isEdit ? 'Save Changes' : 'Save Expense',
                    icon: Icons.save,
                    onPressed: () async {
                      if (!(_formKey.currentState?.validate() ?? false)) return;

                      final amount = double.parse(_amountController.text);
                      final updated = Expense(
                        id: _original?.id ?? const Uuid().v4(),
                        amountMinor: (amount * 100).round(),
                        categoryId: _selectedCategory!.id,
                        note: _noteController.text,
                        date: _selectedDate,
                      );

                      if (isEdit) {
                        await controller.update(updated);
                      } else {
                        await controller.add(updated);
                      }

                      if (!mounted) return;
                      // Return to the previous screen naturally
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
