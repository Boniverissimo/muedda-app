import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';

import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/credit_cards/presentation/pages/credit_card_purchases_page.dart';
import '../../features/credit_cards/presentation/pages/credit_cards_page.dart';
import '../../features/navigation/presentation/pages/main_navigation_page.dart';
import '../../features/payables_receivables/presentation/pages/payables_receivables_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/smart_entry/presentation/pages/smart_entry_page.dart';
import '../../features/recurring_transactions/presentation/pages/recurring_transactions_page.dart';
import '../../features/transactions/presentation/pages/new_transaction_page.dart';

abstract final class AppRouter {
  static const String home = '/';
  static const String accounts = '/accounts';
  static const String categories = '/categories';
  static const String budgets = '/budgets';
  static const String creditCards = '/credit-cards';
  static const String creditCardPurchases = '/credit-cards/purchases';
  static const String reports = '/reports';
  static const String payablesReceivables = '/payables-receivables';
  static const String recurringTransactions = '/recurring-transactions';
  static const String newTransaction = '/transactions/new';
  static const String smartEntry = '/transactions/smart-entry';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    overridePlatformDefaultLocation: true,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: home,
        builder: (context, state) {
          return const MainNavigationPage();
        },
      ),
      GoRoute(
        path: accounts,
        builder: (context, state) {
          return const AccountsPage();
        },
      ),
      GoRoute(
        path: categories,
        builder: (context, state) {
          return const CategoriesPage();
        },
      ),
      GoRoute(
        path: budgets,
        builder: (context, state) {
          return const BudgetsPage();
        },
      ),
      GoRoute(
        path: creditCards,
        builder: (context, state) {
          return const CreditCardsPage();
        },
      ),
      GoRoute(
        path: creditCardPurchases,
        builder: (context, state) {
          final card = state.extra as CreditCard;
          return CreditCardPurchasesPage(creditCard: card);
        },
      ),
      GoRoute(
        path: reports,
        builder: (context, state) {
          return const ReportsPage();
        },
      ),
      GoRoute(
        path: payablesReceivables,
        builder: (context, state) {
          return const PayablesReceivablesPage();
        },
      ),
      GoRoute(
        path: recurringTransactions,
        builder: (context, state) {
          return const RecurringTransactionsPage();
        },
      ),
      GoRoute(
        path: smartEntry,
        builder: (context, state) {
          return const SmartEntryPage();
        },
      ),
      GoRoute(
        path: newTransaction,
        builder: (context, state) {
          final card = state.extra is CreditCard
              ? state.extra as CreditCard
              : null;
          return NewTransactionPage(
            initialType: card == null ? 'expense' : 'card',
            initialCreditCardId: card?.id,
          );
        },
      ),
    ],
  );
}
