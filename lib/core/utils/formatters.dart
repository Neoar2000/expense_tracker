import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
String formatMinor(int minor) => _currency.format(minor / 100.0);

final _date = DateFormat.yMMMd();
String formatDate(DateTime d) => _date.format(d);
