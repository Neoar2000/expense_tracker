import 'package:go_router/go_router.dart';

import '../features/expenses/presentation/pages/dashboard_page.dart';
import '../features/expenses/presentation/pages/expenses_list_page.dart';
import '../features/expenses/presentation/pages/add_edit_expense_page.dart';

/// Configures all app routes and enables proper push/pop navigation
/// so that iOS back swipe and Android system back work out of the box.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/expenses',
        name: 'expenses',
        builder: (context, state) => const ExpensesListPage(),
      ),
      GoRoute(
        path: '/add',
        name: 'addExpense',
        builder: (context, state) => const AddEditExpensePage(),
      ),
      GoRoute(
        path: '/edit/:id',
        name: 'editExpense',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditExpensePage(expenseId: id);
        },
      ),
    ],
  );
}
