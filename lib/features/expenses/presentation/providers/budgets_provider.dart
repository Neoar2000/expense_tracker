import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:expense_tracker/core/services/local_notification_service.dart';

import '../../data/models/budget_nudge_log.dart';
import '../../data/models/category.dart';
import '../../data/models/category_budget.dart';
import '../../data/models/default_budgets.dart';
import '../../data/repositories/budget_nudge_log_repo.dart';
import '../../data/repositories/category_budget_repo.dart';
import '../../domain/budget_nudge_service.dart';
import 'categories_provider.dart';
import 'filters_provider.dart';
import 'stats_provider.dart';

final categoryBudgetsBoxProvider = Provider<Box<CategoryBudget>>((ref) {
  return Hive.box<CategoryBudget>('category_budgets');
});

final categoryBudgetRepoProvider = Provider<CategoryBudgetRepository>((ref) {
  final box = ref.watch(categoryBudgetsBoxProvider);
  return CategoryBudgetRepository(box);
});

final budgetNudgeLogBoxFutureProvider =
    FutureProvider<Box<BudgetNudgeLog>>((ref) async {
  if (Hive.isBoxOpen('budget_nudge_logs')) {
    return Hive.box<BudgetNudgeLog>('budget_nudge_logs');
  }
  return Hive.openBox<BudgetNudgeLog>('budget_nudge_logs');
});

final budgetNudgeLogRepoFutureProvider =
    FutureProvider<BudgetNudgeLogRepository>((ref) async {
  final box = await ref.watch(budgetNudgeLogBoxFutureProvider.future);
  return BudgetNudgeLogRepository(box);
});

class BudgetsController extends Notifier<List<CategoryBudget>> {
  late final CategoryBudgetRepository _repo;

  @override
  List<CategoryBudget> build() {
    _repo = ref.read(categoryBudgetRepoProvider);
    return _repo.list();
  }

  Future<void> upsert(CategoryBudget budget) async {
    await _repo.upsert(budget);
    refresh();
  }

  Future<void> markAlert(CategoryBudget budget, int level) async {
    await _repo.markAlert(budget: budget, alertLevel: level);
    refresh();
  }

  Future<void> ensureMonthBudgets(
    Iterable<Category> categories,
    DateTime month,
  ) async {
    final normalized = DateTime(month.year, month.month, 1);
    final defaults = defaultBudgetsForMonth(categories, normalized);
    for (final budget in defaults) {
      if (_repo.exists(budget.id)) continue;
      await _repo.upsert(budget);
    }
    refresh();
  }

  void refresh() => state = _repo.list();
}

final budgetsProvider =
    NotifierProvider<BudgetsController, List<CategoryBudget>>(
  BudgetsController.new,
);

enum BudgetAlertLevel {
  none,
  warning,
  critical;

  int get severity => index;
}

class BudgetProgress {
  final CategoryBudget budget;
  final Category category;
  final int spentMinor;
  final int remainingMinor;
  final double utilization;
  final BudgetAlertLevel alertLevel;

  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spentMinor,
    required this.remainingMinor,
    required this.utilization,
    required this.alertLevel,
  });

  bool get hasLimit => budget.limitMinor > 0;
  bool get isExceeded => spentMinor >= budget.limitMinor;
}

class BudgetAlert {
  final BudgetProgress progress;
  final BudgetAlertLevel level;
  final bool triggerPush;
  final bool triggerEmail;

  const BudgetAlert({
    required this.progress,
    required this.level,
    required this.triggerPush,
    required this.triggerEmail,
  });

  bool get shouldDispatch => triggerPush || triggerEmail;
}

BudgetAlertLevel _levelFor(double utilization, CategoryBudget budget) {
  if (!budget.pushNudgesEnabled && !budget.emailNudgesEnabled) {
    return BudgetAlertLevel.none;
  }
  if (utilization >= 1) {
    return BudgetAlertLevel.critical;
  }
  if (utilization >= budget.warningThreshold) {
    return BudgetAlertLevel.warning;
  }
  return BudgetAlertLevel.none;
}

final monthlyBudgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final month = ref.watch(filtersProvider).month;
  final budgets = ref.watch(budgetsProvider);
  final categories = ref.watch(allCategoriesProvider);
  final stats = ref.watch(monthStatsProvider);
  final totalsByCategory = <String, int>{
    for (final entry in stats.byCategory) entry.categoryId: entry.totalMinor,
  };

  final normalized = DateTime(month.year, month.month, 1);
  final monthBudgets = budgets
      .where((b) => b.year == normalized.year && b.month == normalized.month)
      .toList();

  return monthBudgets.map((budget) {
    final category = categories.firstWhere(
      (c) => c.id == budget.categoryId,
      orElse: () =>
          Category(id: budget.categoryId, name: 'Unknown', color: 0xFF90A4AE),
    );
    final spentMinor = totalsByCategory[budget.categoryId] ?? 0;
    final utilization =
        budget.limitMinor == 0 ? 0.0 : spentMinor / budget.limitMinor;
    final remaining =
        spentMinor >= budget.limitMinor ? 0 : budget.limitMinor - spentMinor;
    final level = _levelFor(utilization, budget);

    return BudgetProgress(
      budget: budget,
      category: category,
      spentMinor: spentMinor,
      remainingMinor: remaining,
      utilization: utilization,
      alertLevel: level,
    );
  }).toList()
    ..sort(
      (a, b) => b.alertLevel.severity.compareTo(a.alertLevel.severity),
    );
});

final budgetProgressByCategoryProvider = Provider<Map<String, BudgetProgress>>(
  (ref) {
    final progress = ref.watch(monthlyBudgetProgressProvider);
    return {
      for (final item in progress) item.budget.categoryId: item,
    };
  },
);

final budgetAlertsProvider = Provider<List<BudgetAlert>>((ref) {
  final progress = ref.watch(monthlyBudgetProgressProvider);
  return progress.where((p) => p.alertLevel != BudgetAlertLevel.none).map((p) {
    final budget = p.budget;
    final lastLevel = budget.lastAlertLevel ?? 0;
    final shouldTrigger = p.alertLevel.severity > lastLevel;
    return BudgetAlert(
      progress: p,
      level: p.alertLevel,
      triggerPush: shouldTrigger && budget.pushNudgesEnabled,
      triggerEmail: shouldTrigger && budget.emailNudgesEnabled,
    );
  }).toList();
});

final budgetNudgeServiceFutureProvider =
    FutureProvider<BudgetNudgeService>((ref) async {
  final repo = ref.watch(categoryBudgetRepoProvider);
  final logRepo = await ref.watch(budgetNudgeLogRepoFutureProvider.future);
  final notifications = ref.watch(localNotificationServiceProvider);
  return BudgetNudgeService(repo, logRepo, notifications);
});

final recentBudgetNudgesFutureProvider =
    FutureProvider<List<BudgetNudgeLog>>((ref) async {
  final repo = await ref.watch(budgetNudgeLogRepoFutureProvider.future);
  return repo.listRecent();
});

final budgetNudgesForMonthFutureProvider =
    FutureProvider.family<List<BudgetNudgeLog>, DateTime>((ref, month) async {
  final repo = await ref.watch(budgetNudgeLogRepoFutureProvider.future);
  return repo.listForMonth(month);
});
