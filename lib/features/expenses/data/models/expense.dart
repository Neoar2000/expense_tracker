import 'package:hive/hive.dart';
part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id; // uuid
  @HiveField(1)
  final int amountMinor; // store in cents to avoid double precision issues
  @HiveField(2)
  final String categoryId;
  @HiveField(3)
  final String note;
  @HiveField(4)
  final DateTime date;
  @HiveField(5)
  final String currencyCode; // e.g., "USD"

  Expense({
    required this.id,
    required this.amountMinor,
    required this.categoryId,
    required this.note,
    required this.date,
    this.currencyCode = 'USD',
  });

  Expense copyWith({
    String? id,
    int? amountMinor,
    String? categoryId,
    String? note,
    DateTime? date,
    String? currencyCode,
  }) {
    return Expense(
      id: id ?? this.id,
      amountMinor: amountMinor ?? this.amountMinor,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
