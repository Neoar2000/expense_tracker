import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/adaptive_dialog.dart';
import '../../data/models/expense.dart';
import '../../data/models/category.dart';
import '../providers/expenses_provider.dart';
import '../providers/filters_provider.dart';
import '../providers/categories_provider.dart';
import '../widgets/expense_tile.dart';

class ExpensesListPage extends ConsumerStatefulWidget {
  const ExpensesListPage({super.key});

  @override
  ConsumerState<ExpensesListPage> createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends ConsumerState<ExpensesListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return AdaptiveDialog.confirm(
      context,
      title: 'Delete expense?',
      message: 'This action cannot be undone.',
      okText: 'Delete',
    );
  }

  Future<void> _pickDateRange(FilterState filters) async {
    final now = DateTime.now();
    final initialRange =
        filters.dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDateRange: filters.dateRange ?? initialRange,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Filter by date range',
    );
    if (!mounted) return;
    if (picked != null) {
      ref.read(filtersProvider.notifier).setDateRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(filtersProvider);
    if (_searchController.text != filters.query) {
      _searchController
        ..text = filters.query
        ..selection = TextSelection.collapsed(offset: filters.query.length);
    }

    final allExpenses = ref.watch(expensesProvider);
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final categories = ref.watch(allCategoriesProvider);
    final controller = ref.read(expensesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // native back
        ),
      ),
      floatingActionButton: Platform.isIOS
          ? Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 12),
              child: Hero(
                tag: 'add-expense-cta',
                child: CupertinoButton.filled(
                  onPressed: () => context.push('/add'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add, size: 18),
                      SizedBox(width: 8),
                      Text('Add'),
                    ],
                  ),
                ),
              ),
            )
          : FloatingActionButton.extended(
              heroTag: 'add-expense-cta',
              onPressed: () => context.push('/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
      body: allExpenses.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                _FiltersBar(
                  controller: _searchController,
                  filters: filters,
                  categories: categories,
                  onQueryChanged: (value) =>
                      ref.read(filtersProvider.notifier).setQuery(value),
                  onCategoryChanged: (value) => ref
                      .read(filtersProvider.notifier)
                      .setCategory(
                        value == null || value.isEmpty ? null : value,
                      ),
                  onDateTap: () => _pickDateRange(filters),
                  onClearDate: filters.dateRange == null
                      ? null
                      : () => ref
                            .read(filtersProvider.notifier)
                            .setDateRange(null),
                  onClearAll: filters.hasActiveFilters
                      ? () {
                          ref.read(filtersProvider.notifier).clearFilters();
                          FocusScope.of(context).unfocus();
                        }
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: AppDurations.short,
                        child: Text(
                          filteredExpenses.isEmpty
                              ? 'No matching expenses'
                              : 'Showing ${filteredExpenses.length} of ${allExpenses.length}',
                          key: ValueKey(
                            '${filteredExpenses.length}-${allExpenses.length}',
                          ),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (filters.hasActiveFilters)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Filters on',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 0.6,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? _NoResults(query: filters.query)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final Expense e = filteredExpenses[index];

                            return Dismissible(
                              key: ValueKey(e.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),

                              // confirm before deleting (adaptive)
                              confirmDismiss: (_) => _confirmDelete(context),

                              // delete after animation
                              onDismissed: (_) async {
                                await controller.deleteById(e.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Deleted expense #${e.id.substring(0, 6)}',
                                    ),
                                  ),
                                );
                              },

                              child: ExpenseTile(expense: e),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.controller,
    required this.filters,
    required this.categories,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onDateTap,
    required this.onClearDate,
    required this.onClearAll,
  });

  final TextEditingController controller;
  final FilterState filters;
  final List<Category> categories;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onDateTap;
  final VoidCallback? onClearDate;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final hasFilters = filters.hasActiveFilters;
    final theme = Theme.of(context);
    Category? selectedCategory;
    if (filters.categoryId != null) {
      for (final c in categories) {
        if (c.id == filters.categoryId) {
          selectedCategory = c;
          break;
        }
      }
    }
    String dateLabel = 'Any time';
    if (filters.dateRange != null) {
      final start = formatDate(filters.dateRange!.start);
      final end = formatDate(filters.dateRange!.end);
      dateLabel = '$start - $end';
    }

    return AnimatedContainer(
      duration: AppDurations.short,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: 'Search notes or ID',
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: AppDurations.short,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey<String?>(filters.categoryId),
                    value: filters.categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All categories'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(
                            '${c.emoji.isNotEmpty ? '${c.emoji} ' : ''}${c.name}',
                          ),
                        ),
                      ),
                    ],
                    onChanged: onCategoryChanged,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onDateTap,
                  icon: const Icon(Icons.event),
                  label: Text(dateLabel),
                ),
                if (filters.dateRange != null)
                  IconButton(
                    tooltip: 'Clear date range',
                    onPressed: onClearDate,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (selectedCategory != null)
                  _ActiveFilterChip(
                    label:
                        '${selectedCategory!.emoji.isNotEmpty ? '${selectedCategory!.emoji} ' : ''}${selectedCategory!.name}',
                    onDeleted: () => onCategoryChanged(null),
                  ),
                if (filters.dateRange != null)
                  _ActiveFilterChip(
                    label: dateLabel,
                    onDeleted: onClearDate ?? () {},
                  ),
                if (filters.query.isNotEmpty)
                  _ActiveFilterChip(
                    label: '"${filters.query}"',
                    onDeleted: () => onQueryChanged(''),
                  ),
              ],
            ),
          ],
          AnimatedSwitcher(
            duration: AppDurations.short,
            child: hasFilters && onClearAll != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onClearAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset filters'),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.primary,
      ),
      deleteIconColor: theme.colorScheme.primary,
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queryText = query.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 12),
            Text(
              'No expenses match your filters',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (queryText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Tried searching for "$queryText".',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
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
          ],
        ),
      ),
    );
  }
}
