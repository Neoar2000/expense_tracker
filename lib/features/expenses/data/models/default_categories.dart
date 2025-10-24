import 'category.dart';

List<Category> defaultCategories() {
  return [
    Category(id: 'food', name: 'Food', color: 0xFFE57373, emoji: '🍔'),
    Category(id: 'transport', name: 'Transport', color: 0xFF64B5F6, emoji: '🚌'),
    Category(id: 'housing', name: 'Housing', color: 0xFFFFB74D, emoji: '🏠'),
    Category(id: 'groceries', name: 'Groceries', color: 0xFF66BB6A, emoji: '🛒'),
    Category(id: 'travel', name: 'Travel', color: 0xFF4DD0E1, emoji: '✈️'),
    Category(id: 'shopping', name: 'Shopping', color: 0xFF81C784, emoji: '🛍️'),
    Category(id: 'health', name: 'Health', color: 0xFFBA68C8, emoji: '💊'),
    Category(
        id: 'entertainment',
        name: 'Entertainment',
        color: 0xFFA1887F,
        emoji: '🎮'),
    Category(id: 'other', name: 'Other', color: 0xFF90A4AE, emoji: '✨'),
  ];
}
