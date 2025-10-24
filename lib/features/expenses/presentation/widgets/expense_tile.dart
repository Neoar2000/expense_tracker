import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesBox = Hive.box<Category>('categories');
    final cat = categoriesBox.values.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () =>
          Category(id: 'other', name: 'Other', color: 0xFF90A4AE, emoji: '✨'),
    );
    final accent = Color(cat.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/edit/${expense.id}'),
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: AppDurations.short,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    cat.emoji.isNotEmpty ? cat.emoji : '💵',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.note.isEmpty
                          ? formatDate(expense.date)
                          : '${expense.note} • ${formatDate(expense.date)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMinor(expense.amountMinor),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#${expense.id.substring(0, 4).toUpperCase()}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent.darken(),
                        letterSpacing: 0.8,
                      ),
                    ),
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

extension on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }
}
