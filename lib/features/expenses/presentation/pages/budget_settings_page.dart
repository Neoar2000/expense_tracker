import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_system.dart';
import '../../../../core/utils/adaptive_feedback.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/models/budget_nudge_log.dart';
import '../../data/models/category.dart';
import '../../data/models/category_budget.dart';
import '../providers/budgets_provider.dart';
import '../providers/categories_provider.dart';

class BudgetSettingsPage extends ConsumerStatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  ConsumerState<BudgetSettingsPage> createState() =>
      _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends ConsumerState<BudgetSettingsPage> {
  late DateTime _month;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;

  final Map<String, TextEditingController> _limitControllers = {};
  final Map<String, double> _thresholds = {};
  final Map<String, bool> _pushNudges = {};
  final Map<String, bool> _emailNudges = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  @override
  void dispose() {
    for (final controller in _limitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _hydrate() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });
    final categories = ref.read(allCategoriesProvider);
    await ref
        .read(budgetsProvider.notifier)
        .ensureMonthBudgets(categories, _month);
    final budgets = ref.read(budgetsProvider);
    final monthBudgets = _budgetsForMonth(budgets);

    for (final controller in _limitControllers.values) {
      controller.dispose();
    }
    _limitControllers.clear();
    _thresholds.clear();
    _pushNudges.clear();
    _emailNudges.clear();

    for (final category in categories) {
      final budget = monthBudgets.firstWhere(
        (b) => b.categoryId == category.id,
        orElse: () => CategoryBudget.forMonth(
          categoryId: category.id,
          month: _month,
          limitMinor: 0,
        ),
      );
      _limitControllers[category.id] = TextEditingController(
        text: budget.limitMinor == 0
            ? ''
            : (budget.limitMinor / 100).toStringAsFixed(2),
      );
      _thresholds[category.id] = budget.warningThreshold;
      _pushNudges[category.id] = budget.pushNudgesEnabled;
      _emailNudges[category.id] = budget.emailNudgesEnabled;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _dirty = false;
    });
  }

  List<CategoryBudget> _budgetsForMonth(List<CategoryBudget> budgets) {
    return budgets
        .where((b) => b.year == _month.year && b.month == _month.month)
        .toList();
  }

  void _markDirty() {
    if (_dirty) return;
    setState(() {
      _dirty = true;
    });
  }

  Future<void> _changeMonth(int delta) async {
    if (_saving) return;
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
    await _hydrate();
  }

  Future<void> _copyFromPreviousMonth() async {
    final prev = DateTime(_month.year, _month.month - 1, 1);
    final budgets = ref.read(budgetsProvider);
    final previousBudgets =
        budgets.where((b) => b.year == prev.year && b.month == prev.month);
    if (previousBudgets.isEmpty) {
      if (mounted) {
        AdaptiveFeedback.info(
          context,
          'No budgets found for ${_formatMonth(prev)}',
        );
      }
      return;
    }
    for (final entry in previousBudgets) {
      final controller = _limitControllers[entry.categoryId];
      if (controller != null) {
        controller.text = entry.limitMinor == 0
            ? ''
            : (entry.limitMinor / 100).toStringAsFixed(2);
      }
      _thresholds[entry.categoryId] = entry.warningThreshold;
      _pushNudges[entry.categoryId] = entry.pushNudgesEnabled;
      _emailNudges[entry.categoryId] = entry.emailNudgesEnabled;
    }
    _markDirty();
    setState(() {});
  }

  Future<void> _saveBudgets() async {
    if (_saving) return;
    setState(() {
      _saving = true;
    });
    final notifier = ref.read(budgetsProvider.notifier);
    final categories = ref.read(allCategoriesProvider);
    final futures = <Future<void>>[];
    for (final category in categories) {
      final controller = _limitControllers[category.id];
      final limitMinor = _parseMajorToMinor(controller?.text ?? '');
      final threshold = _thresholds[category.id] ?? 0.85;
      final push = _pushNudges[category.id] ?? true;
      final email = _emailNudges[category.id] ?? true;

      final existing = _budgetsForMonth(ref.read(budgetsProvider)).firstWhere(
        (b) => b.categoryId == category.id,
        orElse: () => CategoryBudget.forMonth(
          categoryId: category.id,
          month: _month,
          limitMinor: 0,
        ),
      );

      futures.add(
        notifier.upsert(
          existing.copyWith(
            limitMinor: limitMinor,
            warningThreshold: threshold,
            pushNudgesEnabled: push,
            emailNudgesEnabled: email,
          ),
        ),
      );
    }
    await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = false;
    });
    AdaptiveFeedback.info(context, 'Budgets saved for ${_formatMonth(_month)}');
  }

  int _parseMajorToMinor(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (sanitized.isEmpty) return 0;
    final value = double.tryParse(sanitized);
    if (value == null) return 0;
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(allCategoriesProvider);
    final logsAsync = ref.watch(budgetNudgesForMonthFutureProvider(_month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Goals'),
        actions: [
          const ThemeToggleButton(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Copy last month',
            onPressed: _loading ? null : _copyFromPreviousMonth,
            icon: const Icon(Icons.repeat_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _hydrate,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  _MonthSelector(
                    label: _formatMonth(_month),
                    onPrev: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
                  ),
                  const SizedBox(height: 12),
                  for (final category in categories)
                    _BudgetCard(
                      category: category,
                      controller: _limitControllers[category.id]!,
                      threshold: _thresholds[category.id] ?? 0.85,
                      pushEnabled: _pushNudges[category.id] ?? true,
                      emailEnabled: _emailNudges[category.id] ?? true,
                      onThresholdChanged: (value) {
                        setState(() {
                          _thresholds[category.id] = value;
                        });
                        _markDirty();
                      },
                      onPushChanged: (value) {
                        setState(() {
                          _pushNudges[category.id] = value;
                        });
                        _markDirty();
                      },
                      onEmailChanged: (value) {
                        setState(() {
                          _emailNudges[category.id] = value;
                        });
                        _markDirty();
                      },
                      onLimitChanged: () => _markDirty(),
                    ),
                  const SizedBox(height: 24),
                  _NudgeHistorySection(
                    logs: logsAsync,
                    monthLabel: _formatMonth(_month),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: (!_dirty || _saving)
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _saveBudgets();
                  },
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving
                ? 'Saving...'
                : _dirty
                    ? 'Save budgets'
                    : 'Saved'),
          ),
        ),
      ),
    );
  }

  String _formatMonth(DateTime m) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[m.month - 1]} ${m.year}';
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.category,
    required this.controller,
    required this.threshold,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.onThresholdChanged,
    required this.onPushChanged,
    required this.onEmailChanged,
    required this.onLimitChanged,
  });

  final Category category;
  final TextEditingController controller;
  final double threshold;
  final bool pushEnabled;
  final bool emailEnabled;
  final ValueChanged<double> onThresholdChanged;
  final ValueChanged<bool> onPushChanged;
  final ValueChanged<bool> onEmailChanged;
  final VoidCallback onLimitChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.color);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Text(
                    category.emoji.isNotEmpty ? category.emoji : '💰',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Monthly cap',
                prefixText: '\$',
                helperText: 'Leave empty for no cap',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: (_) => onLimitChanged(),
            ),
            const SizedBox(height: 16),
            Text(
              'Warn me at ${(threshold * 100).round()}% of the cap',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Slider(
              value: threshold.clamp(0.5, 1.0),
              min: 0.5,
              max: 1.0,
              divisions: 5,
              activeColor: color,
              label: '${(threshold * 100).round()}%',
              onChanged: (value) {
                HapticFeedback.selectionClick();
                onThresholdChanged(value);
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: pushEnabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                onPushChanged(value);
              },
              title: const Text('Push / in-app nudges'),
              subtitle: const Text('Show local notifications when limits near.'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: emailEnabled,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                onEmailChanged(value);
              },
              title: const Text('Email nudges'),
              subtitle: const Text('Log an email-ready alert for follow up.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgeHistorySection extends StatelessWidget {
  const _NudgeHistorySection({
    required this.logs,
    required this.monthLabel,
  });

  final AsyncValue<List<BudgetNudgeLog>> logs;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Nudge history',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  monthLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            logs.when(
              data: (items) => items.isEmpty
                  ? Text(
                      'No nudges logged for this month yet.',
                      style: theme.textTheme.bodyMedium,
                    )
                  : Column(
                      children: items
                          .map(
                            (log) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                log.alertLevel >=
                                        BudgetAlertLevel.critical.severity
                                    ? Icons.error_rounded
                                    : Icons.warning_amber_rounded,
                                color: log.alertLevel >=
                                        BudgetAlertLevel.critical.severity
                                    ? AppColors.danger
                                    : AppColors.warning,
                              ),
                              title: Text(log.categoryName),
                              subtitle: Text(
                                '${(log.utilization * 100).toStringAsFixed(0)}% • ${_relativeTime(log.createdAt)}',
                              ),
                              trailing: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (log.pushSent)
                                    const Text(
                                      'Push',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  if (log.emailSent)
                                    const Text(
                                      'Email',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text(
                'Could not load nudges: $err',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
