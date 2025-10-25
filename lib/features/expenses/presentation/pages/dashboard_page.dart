import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../app/navigation_observer.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/services/csv_exporter.dart';
import '../../../../core/widgets/adaptive_dialog.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/category.dart';
import '../providers/budgets_provider.dart';
import '../providers/filters_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/stats_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with RouteAware, SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _heroAnimation;
  late final Animation<double> _kpiAnimation;
  late final Animation<double> _chartsAnimation;
  late final ProviderSubscription<MonthStats> _statsSubscription;
  late final ProviderSubscription<List<BudgetAlert>> _budgetAlertsSubscription;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: AppDurations.long,
    );
    _heroAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
    );
    _kpiAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutBack),
    );
    _chartsAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
    );

    _statsSubscription = ref.listenManual<MonthStats>(
      monthStatsProvider,
      (_, __) => _replayAnimations(),
      fireImmediately: true,
    );
    _budgetAlertsSubscription = ref.listenManual<List<BudgetAlert>>(
      budgetAlertsProvider,
      (_, next) => _handleBudgetAlerts(next),
      fireImmediately: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _replayAnimations());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _statsSubscription.close();
    _budgetAlertsSubscription.close();
    _entryController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() => _replayAnimations();

  @override
  void didPush() => _replayAnimations();

  void _replayAnimations() {
    if (!mounted) return;
    _entryController
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _handleBudgetAlerts(List<BudgetAlert> alerts) async {
    final actionable = alerts.where((a) => a.shouldDispatch).toList();
    if (actionable.isEmpty) return;
    final service = await ref.read(budgetNudgeServiceFutureProvider.future);
    await service.dispatchAlerts(actionable, mounted ? context : null);
    ref.read(budgetsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decorations = theme.extension<AppDecorations>();
    final stats = ref.watch(monthStatsProvider);
    final categoriesBox = Hive.box<Category>('categories');
    final filterState = ref.watch(filtersProvider);
    final selectedMonth = filterState.month;
    final budgetProgress = ref.watch(monthlyBudgetProgressProvider);

    final byCategoryResolved = stats.byCategory.map((ct) {
      final cat = categoriesBox.values.firstWhere(
        (c) => c.id == ct.categoryId,
        orElse: () =>
            Category(id: 'other', name: 'Other', color: 0xFF90A4AE, emoji: '✨'),
      );
      return (cat: cat, totalMinor: ct.totalMinor);
    }).toList();

    final totalFmt = formatMinor(stats.totalMinor);
    final topCatLabel = byCategoryResolved.isNotEmpty
        ? '${byCategoryResolved.first.cat.emoji.isNotEmpty ? '${byCategoryResolved.first.cat.emoji} ' : ''}${byCategoryResolved.first.cat.name}'
        : 'No category yet';

    final mediaPadding = MediaQuery.of(context).padding.top;
    final topPadding = mediaPadding + kToolbarHeight + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Platform.isIOS
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.04),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Dashboard'),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: Platform.isIOS ? 16 : 20,
              sigmaY: Platform.isIOS ? 16 : 20,
            ),
            child: Container(
              color: Platform.isIOS
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Manage budgets',
            onPressed: () => context.push('/budgets'),
            icon: const Icon(Icons.flag_outlined),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'View expenses',
            onPressed: () => context.push('/expenses'),
            icon: const Icon(Icons.list_rounded),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            tooltip: 'Add expense',
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/add');
            },
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -220,
            left: -120,
            right: -120,
            height: 420,
            child: AnimatedBuilder(
              animation: _heroAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: (_heroAnimation.value * 0.6) + 0.2,
                  child: Transform.scale(
                    scale: 0.95 + (_heroAnimation.value * 0.05),
                    child: child,
                  ),
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient:
                      decorations?.heroGradient as LinearGradient? ??
                      const LinearGradient(
                        colors: [Color(0xFF5C6AC4), Color(0xFF8F7CFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 32),
            children: [
              AnimatedBuilder(
                animation: _heroAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _heroAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _heroAnimation.value) * 24),
                      child: child,
                    ),
                  );
                },
                child: _HeroCard(
                  monthLabel: _formatMonth(selectedMonth),
                  totalLabel: totalFmt,
                  entryCount: stats.count,
                  topCategory: topCatLabel,
                  canExport: stats.count > 0,
                  onPrevMonth: () =>
                      ref.read(filtersProvider.notifier).prevMonth(),
                  onNextMonth: () =>
                      ref.read(filtersProvider.notifier).nextMonth(),
                  onExport: stats.count == 0
                      ? null
                      : () async {
                          final all = ref.read(expensesProvider);
                          final path = await CsvExporter.exportMonthly(
                            all,
                            selectedMonth,
                          );
                          if (!context.mounted || path == null) return;
                          await AdaptiveDialog.alert(
                            context,
                            'Export complete',
                            'Saved to: $path',
                          );
                        },
                ),
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _kpiAnimation,
                builder: (context, child) {
                  final progress = _kpiAnimation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, (1 - progress) * 16),
                      child: child,
                    ),
                  );
                },
                child: _KpiGrid(
                  items: [
                    (
                      title: 'Total spend',
                      value: totalFmt,
                      icon: Icons.pie_chart_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    (
                      title: 'Entries',
                      value: stats.count.toString(),
                      icon: Icons.receipt_long,
                      color: theme.colorScheme.tertiary,
                    ),
                    (
                      title: 'Top category',
                      value: topCatLabel,
                      icon: Icons.star_rounded,
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _chartsAnimation,
                builder: (context, child) {
                  final progress = _chartsAnimation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, (1 - progress) * 12),
                      child: child,
                    ),
                  );
                },
                child: _BudgetGoalsCard(items: budgetProgress),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _chartsAnimation,
                builder: (context, child) {
                  final progress = _chartsAnimation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, (1 - progress) * 12),
                      child: child,
                    ),
                  );
                },
                child: _ChartCard(
                  title: 'By category',
                  trailing: Text(
                    stats.count == 0
                        ? 'No entries'
                        : '${stats.count} purchases',
                    style: theme.textTheme.bodyMedium,
                  ),
                  footer: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: byCategoryResolved.map((e) {
                      final label =
                          '${e.cat.emoji.isNotEmpty ? '${e.cat.emoji} ' : ''}${e.cat.name}';
                      return _LegendDot(
                        color: Color(e.cat.color),
                        label: label,
                      );
                    }).toList(),
                  ),
                  child: SizedBox(
                    height: 240,
                    child: byCategoryResolved.isEmpty
                        ? const Center(child: Text('No data yet'))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 36,
                              sections: _buildPieSections(
                                byCategoryResolved,
                                _chartsAnimation.value,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _chartsAnimation,
                builder: (context, child) {
                  final progress = _chartsAnimation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: progress,
                    child: Transform.translate(
                      offset: Offset(0, (1 - progress) * 12),
                      child: child,
                    ),
                  );
                },
                child: _ChartCard(
                  title: 'Daily trend',
                  trailing: Text(
                    'Avg ${stats.dailyTrend.isEmpty ? '—' : formatMinor(stats.totalMinor ~/ (stats.dailyTrend.isEmpty ? 1 : stats.dailyTrend.length))}/day',
                    style: theme.textTheme.bodyMedium,
                  ),
                  child: SizedBox(
                    height: 240,
                    child: stats.dailyTrend.isEmpty
                        ? const Center(child: Text('No data yet'))
                        : LineChart(
                            _buildLineData(
                              stats.dailyTrend,
                              theme,
                              _chartsAnimation.value,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    List<({Category cat, int totalMinor})> items,
    double progress,
  ) {
    final total = items.fold<int>(0, (s, e) => s + e.totalMinor);
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '—',
          color: Colors.grey.shade200,
          titleStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ];
    }

    final safeProgress = progress.clamp(0.05, 1.0).toDouble();

    return items.map((e) {
      final pct = (e.totalMinor / total) * 100;
      return PieChartSectionData(
        value: e.totalMinor.toDouble() * safeProgress,
        color: Color(e.cat.color),
        title: '${pct.toStringAsFixed(0)}%',
        radius: 70,
        titleStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  LineChartData _buildLineData(
    List<TrendPoint> points,
    ThemeData theme,
    double progress,
  ) {
    final spots = <FlSpot>[];
    double minX = 0, maxX = 0, minY = 0, maxY = 0;

    for (var i = 0; i < points.length; i++) {
      final y = (points[i].totalMinor / 100.0) * progress.clamp(0, 1);
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
    maxY = maxY == minY ? minY + 10 : maxY + yPad;

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        horizontalInterval: ((maxY - minY) / 4)
            .clamp(1, double.infinity)
            .toDouble(),
        getDrawingHorizontalLine: (value) => FlLine(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
          strokeWidth: 1,
        ),
        drawVerticalLine: false,
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              formatMinor((value * 100).round()),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
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
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 4,
          isStrokeCapRound: true,
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.2),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: const FlDotData(show: false),
        ),
      ],
    );
  }

  String _formatMonth(DateTime m) =>
      '${_monthNames[m.month - 1]} ${m.year.toString()}';

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
    'Dec',
  ];
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.monthLabel,
    required this.totalLabel,
    required this.entryCount,
    required this.topCategory,
    required this.canExport,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onExport,
  });

  final String monthLabel;
  final String totalLabel;
  final int entryCount;
  final String topCategory;
  final bool canExport;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decorations = theme.extension<AppDecorations>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient:
            decorations?.heroGradient as LinearGradient? ??
            const LinearGradient(
              colors: [Color(0xFF5C6AC4), Color(0xFF8F7CFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: decorations?.glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MonthButton(icon: Icons.chevron_left, onTap: onPrevMonth),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Spending snapshot',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabel,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _MonthButton(icon: Icons.chevron_right, onTap: onNextMonth),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Total spend',
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: AppDurations.medium,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              totalLabel,
              key: ValueKey(totalLabel),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _InsightChip(
                icon: Icons.receipt_long,
                label: '$entryCount entries',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InsightChip(
                  icon: Icons.star_rounded,
                  label: topCategory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: canExport
                ? () {
                    HapticFeedback.selectionClick();
                    onExport?.call();
                  }
                : null,
            icon: const Icon(Icons.ios_share),
            label: const Text('Export CSV'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: Icon(icon),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.12),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});

  final List<({String title, String value, IconData icon, Color color})> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;
        final bool singleColumn = maxWidth < 360;
        final double tileWidth = singleColumn
            ? maxWidth
            : (maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: tileWidth,
                  child: _KpiCard(
                    title: item.title,
                    value: item.value,
                    icon: item.icon,
                    color: item.color,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.footer,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
        ),
      ),
    );
  }
}

class _BudgetGoalsCard extends StatelessWidget {
  const _BudgetGoalsCard({required this.items});
  final List<BudgetProgress> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLimit =
        items.fold<int>(0, (sum, e) => sum + e.budget.limitMinor);
    final totalSpent = items.fold<int>(0, (sum, e) => sum + e.spentMinor);
    final overallUtilization =
        totalLimit == 0 ? 0.0 : (totalSpent / totalLimit).clamp(0.0, 2.0);
    final statusColor = _statusColor(
      _levelForUtil(overallUtilization),
      theme,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Budget goals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    totalLimit == 0
                        ? 'No caps set'
                        : '${(overallUtilization * 100).toStringAsFixed(0)}% of portfolio limit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Text('No monthly budgets configured yet.')
            else
              Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _BudgetGoalRow(item: item),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  BudgetAlertLevel _levelForUtil(double utilization) {
    if (utilization >= 1) return BudgetAlertLevel.critical;
    if (utilization >= 0.85) return BudgetAlertLevel.warning;
    return BudgetAlertLevel.none;
  }

  Color _statusColor(BudgetAlertLevel level, ThemeData theme) {
    switch (level) {
      case BudgetAlertLevel.none:
        return theme.colorScheme.primary;
      case BudgetAlertLevel.warning:
        return AppColors.warning;
      case BudgetAlertLevel.critical:
        return AppColors.danger;
    }
  }
}

class _BudgetGoalRow extends StatelessWidget {
  const _BudgetGoalRow({required this.item});

  final BudgetProgress item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(item, theme);
    final icon = _statusIcon(item.alertLevel);
    final label = _statusLabel(item);
    final double? percentUsed =
        item.budget.limitMinor == 0 ? null : (item.utilization * 100);

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(item.category.color).withOpacity(0.15),
              child: Text(
                item.category.emoji.isNotEmpty ? item.category.emoji : '💰',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatMinor(item.spentMinor)} of ${formatMinor(item.budget.limitMinor)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: item.utilization.clamp(0.0, 1.0),
            color: statusColor,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _NudgeIcon(
              icon: Icons.notifications_active_outlined,
              enabled: item.budget.pushNudgesEnabled,
              active: item.alertLevel != BudgetAlertLevel.none,
            ),
            const SizedBox(width: 10),
            _NudgeIcon(
              icon: Icons.email_outlined,
              enabled: item.budget.emailNudgesEnabled,
              active: item.alertLevel == BudgetAlertLevel.critical,
            ),
            const Spacer(),
            Text(
              percentUsed == null
                  ? 'No limit'
                  : '${percentUsed.clamp(0, 999).toStringAsFixed(0)}% used',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.budget.lastAlertAt == null
                  ? 'No nudges yet'
                  : 'Last nudge ${_relativeTime(item.budget.lastAlertAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(BudgetProgress item, ThemeData theme) {
    switch (item.alertLevel) {
      case BudgetAlertLevel.none:
        return theme.colorScheme.primary;
      case BudgetAlertLevel.warning:
        return AppColors.warning;
      case BudgetAlertLevel.critical:
        return AppColors.danger;
    }
  }

  IconData _statusIcon(BudgetAlertLevel level) {
    switch (level) {
      case BudgetAlertLevel.none:
        return Icons.check_circle;
      case BudgetAlertLevel.warning:
        return Icons.warning_amber_rounded;
      case BudgetAlertLevel.critical:
        return Icons.error_rounded;
    }
  }

  String _statusLabel(BudgetProgress item) {
    switch (item.alertLevel) {
      case BudgetAlertLevel.none:
        return 'On track';
      case BudgetAlertLevel.warning:
        return 'Warning';
      case BudgetAlertLevel.critical:
        return 'Over';
    }
  }

  String _relativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _NudgeIcon extends StatelessWidget {
  const _NudgeIcon({
    required this.icon,
    required this.enabled,
    required this.active,
  });

  final IconData icon;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = !enabled
        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
        : active
            ? theme.colorScheme.secondary
            : theme.colorScheme.onSurfaceVariant;
    return Icon(icon, size: 18, color: color);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.1),
      ),
      child: Row(
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
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
