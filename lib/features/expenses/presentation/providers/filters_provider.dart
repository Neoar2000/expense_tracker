import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterState {
  final DateTime month; // normalized to first day
  final String query;
  final String? categoryId;
  final DateTimeRange? dateRange;

  const FilterState({
    required this.month,
    this.query = '',
    this.categoryId,
    this.dateRange,
  });

  factory FilterState.currentMonth() {
    final now = DateTime.now();
    return FilterState(month: DateTime(now.year, now.month, 1));
  }

  static const _categorySentinel = Object();
  static const _dateRangeSentinel = Object();

  FilterState copyWith({
    DateTime? month,
    String? query,
    Object? categoryId = _categorySentinel,
    Object? dateRange = _dateRangeSentinel,
  }) {
    return FilterState(
      month: month ?? this.month,
      query: query ?? this.query,
      categoryId: categoryId == _categorySentinel
          ? this.categoryId
          : categoryId as String?,
      dateRange: dateRange == _dateRangeSentinel
          ? this.dateRange
          : dateRange as DateTimeRange?,
    );
  }

  FilterState nextMonth() {
    final m = DateTime(month.year, month.month + 1, 1);
    return copyWith(month: m);
  }

  FilterState prevMonth() {
    final m = DateTime(month.year, month.month - 1, 1);
    return copyWith(month: m);
  }

  bool get hasActiveFilters =>
      query.trim().isNotEmpty || categoryId != null || dateRange != null;
}

class FiltersController extends Notifier<FilterState> {
  @override
  FilterState build() => FilterState.currentMonth();

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: range);
  }

  void clearFilters() {
    state = state.copyWith(
      query: '',
      categoryId: null,
      dateRange: null,
    );
  }

  void setMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month, 1);
    state = state.copyWith(month: normalized);
  }

  void nextMonth() {
    state = state.nextMonth();
  }

  void prevMonth() {
    state = state.prevMonth();
  }
}

final filtersProvider =
    NotifierProvider<FiltersController, FilterState>(FiltersController.new);
