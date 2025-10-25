import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart'; // CupertinoApp
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/security/auth_controller.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/design_system.dart';
import 'core/theme/theme_controller.dart';
import 'features/security/presentation/widgets/auth_gate.dart';
import 'features/expenses/data/models/budget_nudge_log.dart';
import 'features/expenses/data/models/category_budget.dart';
import 'features/expenses/data/models/category.dart';
import 'features/expenses/data/models/default_budgets.dart';
import 'features/expenses/data/models/default_categories.dart';
import 'features/expenses/data/models/expense.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(ExpenseAdapter().typeId)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  if (!Hive.isAdapterRegistered(CategoryAdapter().typeId)) {
    Hive.registerAdapter(CategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(CategoryBudgetAdapter().typeId)) {
    Hive.registerAdapter(CategoryBudgetAdapter());
  }
  if (!Hive.isAdapterRegistered(BudgetNudgeLogAdapter().typeId)) {
    Hive.registerAdapter(BudgetNudgeLogAdapter());
  }

  // Open boxes
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<CategoryBudget>('category_budgets');
  await Hive.openBox<BudgetNudgeLog>('budget_nudge_logs');

  // Seed default categories if empty
  final categoriesBox = Hive.box<Category>('categories');
  final defaults = defaultCategories();
  if (categoriesBox.isEmpty) {
    categoriesBox.addAll(defaults);
  } else {
    final existingIds = categoriesBox.values
        .map((category) => category.id)
        .toSet();
    for (final cat in defaults) {
      if (!existingIds.contains(cat.id)) {
        categoriesBox.add(cat);
      }
    }
  }

  final budgetsBox = Hive.box<CategoryBudget>('category_budgets');
  await _seedBudgets(budgetsBox, categoriesBox.values);

  await LocalNotificationService.instance.init();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const ExpenseApp(),
    ),
  );
}

Future<void> _seedBudgets(
  Box<CategoryBudget> budgetsBox,
  Iterable<Category> categories,
) async {
  if (categories.isEmpty) return;
  final now = DateTime.now();
  for (var offset = -1; offset <= 1; offset++) {
    final month = DateTime(now.year, now.month + offset, 1);
    final defaults = defaultBudgetsForMonth(categories, month);
    for (final budget in defaults) {
      if (budgetsBox.containsKey(budget.id)) continue;
      await budgetsBox.put(budget.id, budget);
    }
  }
}

class ExpenseApp extends ConsumerWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter();
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);

    if (authState.status != AuthStatus.authenticated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const AuthGate(),
      );
    }

    if (Platform.isIOS) {
      // 🍎 iOS look & feel with CupertinoApp
      // We inject Material "scaffolding" via builder so Material widgets (Scaffold, SnackBar, etc.)
      // and MaterialLocalizations work inside our Cupertino shell.
      return CupertinoApp.router(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.cupertino(_resolveBrightness(themeMode)),
        // Provide Material/Cupertino/Widget localizations so Material widgets have strings, etc.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // add others if you localize later
        ],
        // Wrap every page with a Material + ScaffoldMessenger context
        builder: (context, child) {
          final materialTheme = _materialThemeFor(themeMode, context);
          // A global ScaffoldMessenger so SnackBars work under CupertinoApp
          return Theme(
            data: materialTheme,
            child: ScaffoldMessenger(
              child: Material(
                type: MaterialType.transparency,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      );
    } else {
      // 🤖 Material look & feel on Android (normal MaterialApp)
      return MaterialApp.router(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        locale: const Locale('en'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
      );
    }
  }

  Brightness _resolveBrightness(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  ThemeData _materialThemeFor(ThemeMode mode, BuildContext context) {
    switch (mode) {
      case ThemeMode.dark:
        return AppTheme.dark;
      case ThemeMode.light:
        return AppTheme.light;
      case ThemeMode.system:
        final brightness = MediaQuery.maybeOf(context)?.platformBrightness ??
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
    }
  }
}
