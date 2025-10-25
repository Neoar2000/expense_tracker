import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/expense.dart';
import '../providers/budgets_provider.dart';

class ExpenseTile extends ConsumerWidget {
  final Expense expense;
  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesBox = Hive.box<Category>('categories');
    final cat = categoriesBox.values.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () =>
          Category(id: 'other', name: 'Other', color: 0xFF90A4AE, emoji: '✨'),
    );
    final accent = Color(cat.color);
    final progressMap = ref.watch(budgetProgressByCategoryProvider);
    final budgetProgress = progressMap[expense.categoryId];
    final alertLevel = budgetProgress?.alertLevel ?? BudgetAlertLevel.none;
    final alertColor = _alertColor(alertLevel, theme, accent);
    final utilizationPct = budgetProgress == null || budgetProgress.budget.limitMinor == 0
        ? null
        : (budgetProgress.utilization * 100).clamp(0, 999);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/edit/${expense.id}');
        },
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
                    if (budgetProgress != null &&
                        budgetProgress.budget.limitMinor > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value:
                              budgetProgress.utilization.clamp(0.0, 1.0),
                          color: alertColor,
                          backgroundColor:
                              accent.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatMinor(budgetProgress.spentMinor)} of ${formatMinor(budgetProgress.budget.limitMinor)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (alertLevel != BudgetAlertLevel.none) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: alertColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            alertLevel == BudgetAlertLevel.critical
                                ? Icons.error_rounded
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: alertColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alertLevel == BudgetAlertLevel.critical
                                ? 'Over budget'
                                : 'Near limit',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: alertColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
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
                  if (utilizationPct != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${utilizationPct.toStringAsFixed(0)}% of cap',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _alertColor(
    BudgetAlertLevel level,
    ThemeData theme,
    Color fallback,
  ) {
    switch (level) {
      case BudgetAlertLevel.none:
        return fallback;
      case BudgetAlertLevel.warning:
        return AppColors.warning;
      case BudgetAlertLevel.critical:
        return AppColors.danger;
    }
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
