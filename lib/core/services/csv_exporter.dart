import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/expenses/data/models/expense.dart';

class CsvExporter {
  /// Exports all expenses within [month] (first day of month) to a CSV,
  /// returns the file path when the user completes sharing.
  /// Returns `null` if the share sheet is dismissed/cancelled.
  static Future<String?> exportMonthly(
    List<Expense> all,
    DateTime month, {
    String currencySymbol = '\$',
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final endEx = DateTime(month.year, month.month + 1, 1);

    final items = all
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(endEx))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final rows = <List<dynamic>>[
      ['date', 'categoryId', 'amount', 'currency', 'note'],
      for (final e in items)
        [
          _yyyyMmDd(e.date),
          e.categoryId,
          (e.amountMinor / 100.0).toStringAsFixed(2),
          e.currencyCode,
          e.note,
        ]
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final filename = 'expenses_${start.year}_${_two(start.month)}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);

    // Share the file (shows native share sheet)
    final result = await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Monthly expenses: $filename',
    );

    if (result.status == ShareResultStatus.success) {
      return file.path;
    }

    // User dismissed/cancelled: clean up temp file and report null
    if (await file.exists()) {
      await file.delete();
    }
    return null;
  }

  static String _yyyyMmDd(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int n) => n < 10 ? '0$n' : '$n';
}
