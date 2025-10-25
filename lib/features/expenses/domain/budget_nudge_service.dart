import 'package:uuid/uuid.dart';

import 'package:flutter/widgets.dart';

import 'package:expense_tracker/core/utils/adaptive_feedback.dart';
import 'package:expense_tracker/core/services/local_notification_service.dart';

import '../data/models/budget_nudge_log.dart';
import '../data/models/category_budget.dart';
import '../data/repositories/budget_nudge_log_repo.dart';
import '../data/repositories/category_budget_repo.dart';
import '../presentation/providers/budgets_provider.dart';

class BudgetNudgeService {
  BudgetNudgeService(this._budgetRepo, this._logRepo, this._notifications);

  final CategoryBudgetRepository _budgetRepo;
  final BudgetNudgeLogRepository _logRepo;
  final LocalNotificationService _notifications;
  final _uuid = const Uuid();

  Future<void> dispatchAlerts(List<BudgetAlert> alerts, BuildContext? context) async {
    for (final alert in alerts) {
      if (!alert.shouldDispatch) continue;
      final buffer = StringBuffer()
        ..write(
          '[Budgets] ${alert.progress.category.name} ${alert.level.name.toUpperCase()} at ${(alert.progress.utilization * 100).toStringAsFixed(0)}%',
        );
      if (alert.triggerPush) {
        buffer.write(' • push nudge queued');
        await _notifications.showBudgetAlert(
          title: 'Budget alert: ${alert.progress.category.name}',
          body:
              'You\'ve used ${(alert.progress.utilization * 100).toStringAsFixed(0)}% of this cap.',
        );
        if (context != null) {
          AdaptiveFeedback.info(
            context,
            '${alert.progress.category.name} is at ${(alert.progress.utilization * 100).toStringAsFixed(0)}% of its cap.',
          );
        }
      }
      if (alert.triggerEmail) {
        buffer.write(' • email nudge queued');
      }
      // In a real app this is where we would integrate Firebase Cloud Messaging,
      // local notifications, or an email service. For the portfolio build we log
      // the action so reviewers can see the automation hook.
      // ignore: avoid_print
      print(buffer.toString());

      await _budgetRepo.markAlert(
        budget: alert.progress.budget,
        alertLevel: alert.level.severity,
      );

      final log = BudgetNudgeLog(
        id: _uuid.v4(),
        budgetId: alert.progress.budget.id,
        categoryId: alert.progress.category.id,
        categoryName: alert.progress.category.name,
        alertLevel: alert.level.severity,
        pushSent: alert.triggerPush,
        emailSent: alert.triggerEmail,
        utilization: alert.progress.utilization,
        createdAt: DateTime.now(),
        message: buffer.toString(),
      );
      await _logRepo.add(log);
    }
  }
}
