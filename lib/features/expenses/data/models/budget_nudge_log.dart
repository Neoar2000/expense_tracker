import 'package:hive/hive.dart';

part 'budget_nudge_log.g.dart';

@HiveType(typeId: 3)
class BudgetNudgeLog extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String budgetId;
  @HiveField(2)
  final String categoryId;
  @HiveField(3)
  final String categoryName;
  @HiveField(4)
  final int alertLevel;
  @HiveField(5)
  final bool pushSent;
  @HiveField(6)
  final bool emailSent;
  @HiveField(7)
  final double utilization;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final String message;

  BudgetNudgeLog({
    required this.id,
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.alertLevel,
    required this.pushSent,
    required this.emailSent,
    required this.utilization,
    required this.createdAt,
    required this.message,
  });
}
