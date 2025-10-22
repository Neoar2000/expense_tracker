import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterState {
  final DateTime month; // normalized to first day
  const FilterState(this.month);

  factory FilterState.currentMonth() {
    final now = DateTime.now();
    return FilterState(DateTime(now.year, now.month, 1));
  }

  FilterState nextMonth() {
    final m = DateTime(month.year, month.month + 1, 1);
    return FilterState(m);
  }

  FilterState prevMonth() {
    final m = DateTime(month.year, month.month - 1, 1);
    return FilterState(m);
  }
}

final filtersProvider =
    StateProvider<FilterState>((ref) => FilterState.currentMonth());
