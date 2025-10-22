import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart'; // CupertinoApp
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/router.dart';
import 'features/expenses/data/models/expense.dart';
import 'features/expenses/data/models/category.dart';

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

  // Open boxes
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Category>('categories');

  // Seed default categories if empty
  final categoriesBox = Hive.box<Category>('categories');
  if (categoriesBox.isEmpty) {
    categoriesBox.addAll([
      Category(id: 'food', name: 'Food', color: 0xFFE57373, emoji: '🍔'),
      Category(
          id: 'transport', name: 'Transport', color: 0xFF64B5F6, emoji: '🚌'),
      Category(id: 'housing', name: 'Housing', color: 0xFFFFB74D, emoji: '🏠'),
      Category(
          id: 'shopping', name: 'Shopping', color: 0xFF81C784, emoji: '🛍️'),
      Category(id: 'health', name: 'Health', color: 0xFFBA68C8, emoji: '💊'),
      Category(
          id: 'entertainment',
          name: 'Entertainment',
          color: 0xFFA1887F,
          emoji: '🎮'),
      Category(id: 'other', name: 'Other', color: 0xFF90A4AE, emoji: '✨'),
    ]);
  }

  runApp(const ProviderScope(child: ExpenseApp()));
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter();

    if (Platform.isIOS) {
      // 🍎 iOS look & feel with CupertinoApp
      // We inject Material "scaffolding" via builder so Material widgets (Scaffold, SnackBar, etc.)
      // and MaterialLocalizations work inside our Cupertino shell.
      return CupertinoApp.router(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
          barBackgroundColor: CupertinoColors.systemGrey6,
        ),
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
          // A global ScaffoldMessenger so SnackBars work under CupertinoApp
          return ScaffoldMessenger(
            child: Material(
              // provides Theme/DefaultTextStyle for Material widgets
              type: MaterialType.transparency,
              child: child ?? const SizedBox.shrink(),
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
        ],
      );
    }
  }
}
