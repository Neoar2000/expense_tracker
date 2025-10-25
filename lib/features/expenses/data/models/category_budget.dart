import 'package:hive/hive.dart';

part 'category_budget.g.dart';

@HiveType(typeId: 2)
class CategoryBudget extends HiveObject {
  @HiveField(0)
  final String id; // categoryId-year-month compound key
  @HiveField(1)
  final String categoryId;
  @HiveField(2)
  final int year;
  @HiveField(3)
  final int month;
  @HiveField(4)
  final int limitMinor;
  @HiveField(5)
  final double warningThreshold;
  @HiveField(6)
  final bool pushNudgesEnabled;
  @HiveField(7)
  final bool emailNudgesEnabled;
  @HiveField(8)
  final int? lastAlertLevel;
  @HiveField(9)
  final DateTime? lastAlertAt;

  CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limitMinor,
    this.warningThreshold = 0.85,
    this.pushNudgesEnabled = true,
    this.emailNudgesEnabled = true,
    this.lastAlertLevel,
    this.lastAlertAt,
  });

  factory CategoryBudget.forMonth({
    required String categoryId,
    required DateTime month,
    required int limitMinor,
    double warningThreshold = 0.85,
    bool pushNudgesEnabled = true,
    bool emailNudgesEnabled = true,
  }) {
    final normalized = DateTime(month.year, month.month, 1);
    return CategoryBudget(
      id: compoundId(categoryId, normalized),
      categoryId: categoryId,
      year: normalized.year,
      month: normalized.month,
      limitMinor: limitMinor,
      warningThreshold: warningThreshold,
      pushNudgesEnabled: pushNudgesEnabled,
      emailNudgesEnabled: emailNudgesEnabled,
    );
  }

  CategoryBudget copyWith({
    String? id,
    String? categoryId,
    int? year,
    int? month,
    int? limitMinor,
    double? warningThreshold,
    bool? pushNudgesEnabled,
    bool? emailNudgesEnabled,
    int? lastAlertLevel,
    DateTime? lastAlertAt,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      limitMinor: limitMinor ?? this.limitMinor,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      pushNudgesEnabled: pushNudgesEnabled ?? this.pushNudgesEnabled,
      emailNudgesEnabled: emailNudgesEnabled ?? this.emailNudgesEnabled,
      lastAlertLevel: lastAlertLevel ?? this.lastAlertLevel,
      lastAlertAt: lastAlertAt ?? this.lastAlertAt,
    );
  }

  static String compoundId(String categoryId, DateTime month) {
    return '$categoryId-${month.year}-${month.month}';
  }
}
