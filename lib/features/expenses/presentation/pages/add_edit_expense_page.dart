import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

import '../../../../core/theme/design_system.dart';
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
    final theme = Theme.of(context);
    final controller = ref.read(expensesProvider.notifier);
    final categoriesBox = Hive.box<Category>('categories');
    final categories = categoriesBox.values.toList();

    final isEdit = widget.expenseId != null;
    final accent = Color(
      _selectedCategory?.color ?? theme.colorScheme.primary.value,
    );
    final emoji = _selectedCategory?.emoji.isNotEmpty == true
        ? _selectedCategory!.emoji
        : '💸';

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
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              HeroMode(
                enabled: !isEdit,
                child: Hero(
                  tag: 'add-expense-cta',
                  child: Material(
                    color: Colors.transparent,
                    child: _ExpenseHeader(
                      isEdit: isEdit,
                      accent: accent,
                      emoji: emoji,
                      categoryLabel:
                          _selectedCategory?.name ?? 'Choose a category',
                      dateLabel: formatDate(_selectedDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Amount'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter an amount';
                          }
                          final d = double.tryParse(v);
                          if (d == null || d <= 0) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Date'),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, color: accent),
                                const SizedBox(width: 12),
                                Text(
                                  formatDate(_selectedDate),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Category'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Category>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.category),
                          hintText: 'Select a category',
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Text(
                                      c.emoji.isNotEmpty ? '${c.emoji} ' : '',
                                    ),
                                    Text(c.name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                        validator: (v) =>
                            v == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 18),
                      const _SectionLabel('Note'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: 'Add a quick note (optional)',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AdaptiveButton(
                            label: 'Cancel',
                            style: AdaptiveButtonStyle.secondary,
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
                              if (!(_formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }

                              final amount = double.parse(
                                _amountController.text,
                              );
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader({
    required this.isEdit,
    required this.accent,
    required this.emoji,
    required this.categoryLabel,
    required this.dateLabel,
  });

  final bool isEdit;
  final Color accent;
  final String emoji;
  final String categoryLabel;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 320;
        final badge = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        );

        final dateTexts = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduled on',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            Text(
              dateLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

        final trailingIcon = Icon(
          isEdit ? Icons.edit_note : Icons.auto_awesome,
          color: Colors.white70,
          size: 32,
        );

        Widget content = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Update expense' : 'New expense',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: AppDurations.medium,
                child: Text(
                  categoryLabel,
                  key: ValueKey(categoryLabel),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(height: 12),
                    dateTexts,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: trailingIcon),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    badge,
                    const SizedBox(width: 16),
                    Expanded(child: dateTexts),
                    trailingIcon,
                  ],
                ),
            ],
          ),
        );

        const double preferredWidth = 360;
        const double preferredHeight = 220;
        final constrained = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: preferredWidth),
          child: content,
        );

        final fitsHeight =
            constraints.maxHeight.isInfinite ||
            constraints.maxHeight >= preferredHeight;

        if (!isCompact && fitsHeight) {
          return constrained;
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: constrained,
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 1.1,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
