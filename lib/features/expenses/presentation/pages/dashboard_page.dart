import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/services/csv_exporter.dart';
import '../../data/models/category.dart';
import '../providers/stats_provider.dart';
import '../providers/filters_provider.dart';
import '../providers/expenses_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(monthStatsProvider);
    final categoriesBox = Hive.box<Category>('categories');
    final selectedMonth = ref.watch(filtersProvider).month;

    final byCategoryResolved = stats.byCategory.map((ct) {
      final cat = categoriesBox.values.firstWhere(
        (c) => c.id == ct.categoryId,
        orElse: () => Category(
          id: 'other',
          name: 'Other',
          color: 0xFF90A4AE,
          emoji: '✨',
        ),
      );
      return (cat: cat, totalMinor: ct.totalMinor);
    }).toList();

    final totalFmt = formatMinor(stats.totalMinor);
    final topCatLabel =
        byCategoryResolved.isNotEmpty ? byCategoryResolved.first.cat.name : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'View Expenses',
            onPressed: () => context.push('/expenses'), // ✅ push keeps stack
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            tooltip: 'Add Expense',
            onPressed: () => context.push('/add'), // ✅ push keeps back gesture
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month selector + Export
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () {
                      ref.read(filtersProvider.notifier).state =
                          ref.read(filtersProvider).prevMonth();
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _formatMonth(selectedMonth),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: () {
                      ref.read(filtersProvider.notifier).state =
                          ref.read(filtersProvider).nextMonth();
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: stats.count == 0
                        ? null
                        : () async {
                            final all = ref.read(expensesProvider);
                            final path = await CsvExporter.exportMonthly(
                              all,
                              selectedMonth,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Exported CSV to: $path'),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Export'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // KPI cards
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: [
              _KpiCard(title: 'Total', value: totalFmt),
              _KpiCard(title: 'Entries', value: stats.count.toString()),
              _KpiCard(title: 'Top category', value: topCatLabel),
            ],
          ),
          const SizedBox(height: 16),

          // Pie Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'By Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: byCategoryResolved.isEmpty
                        ? const Center(child: Text('No data'))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 32,
                              sections: _buildPieSections(byCategoryResolved),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: byCategoryResolved.map((e) {
                      return _LegendDot(
                        color: Color(e.cat.color),
                        label:
                            '${e.cat.emoji.isNotEmpty ? '${e.cat.emoji} ' : ''}${e.cat.name}',
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trend Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Trend',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: stats.dailyTrend.isEmpty
                        ? const Center(child: Text('No data'))
                        : LineChart(_buildLineData(stats.dailyTrend)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Chart Helpers ---
  List<PieChartSectionData> _buildPieSections(
      List<({Category cat, int totalMinor})> items) {
    final total = items.fold<int>(0, (s, e) => s + e.totalMinor);
    if (total == 0) return [PieChartSectionData(value: 1, title: '—')];

    return items.map((e) {
      final pct = (e.totalMinor / total) * 100;
      return PieChartSectionData(
        value: e.totalMinor.toDouble(),
        color: Color(e.cat.color),
        title: '${pct.toStringAsFixed(0)}%',
        radius: 66,
        titleStyle: const TextStyle(fontWeight: FontWeight.w600),
      );
    }).toList();
  }

  LineChartData _buildLineData(List<TrendPoint> points) {
    final spots = <FlSpot>[];
    double minX = 0, maxX = 0, minY = 0, maxY = 0;

    for (var i = 0; i < points.length; i++) {
      final y = points[i].totalMinor / 100.0;
      spots.add(FlSpot(i.toDouble(), y));
      if (i == 0) {
        minX = maxX = 0;
        minY = maxY = y;
      } else {
        maxX = i.toDouble();
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }

    final yPad = (maxY - minY).clamp(5, 50);
    minY = (minY - yPad).clamp(0, double.infinity);
    maxY = maxY + yPad;

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY == minY ? minY + 10 : maxY,
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 36),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= points.length) {
                return const SizedBox.shrink();
              }
              final d = points[idx].day.day;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('$d', style: const TextStyle(fontSize: 11)),
              );
            },
            interval: (points.length / 6).clamp(1, 7).toDouble(),
          ),
        ),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3,
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  String _formatMonth(DateTime m) {
    return '${_monthNames[m.month - 1]} ${m.year}';
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
}

// --- UI Helpers ---
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  const _KpiCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
