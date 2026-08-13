import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/database/local_database.dart';
import 'daos/user_dao.dart';
import 'repositories/user_repository.dart';
import 'providers/user_provider.dart';
import 'daos/customer_dao.dart';
import 'repositories/customer_repository.dart';
import 'providers/customer_provider.dart';
import 'screens/user/onboarding_screen.dart';
import 'screens/user/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'daos/supplier_dao.dart';
import 'repositories/supplier_repository.dart';
import 'providers/supplier_provider.dart';
import 'screens/supplier/supplier_list_screen.dart';
import 'daos/sale_dao.dart';
import 'daos/sale_installment_dao.dart';
import 'daos/sale_payment_dao.dart';
import 'daos/sale_category_dao.dart';
import 'repositories/sale_repository.dart';
import 'providers/sale_provider.dart';
import 'daos/financial_statement_dao.dart';
import 'repositories/financial_statement_repository.dart';
import 'providers/financial_statement_provider.dart';
import 'daos/expense_dao.dart';
import 'daos/expense_category_dao.dart';
import 'repositories/expense_repository.dart';
import 'providers/expense_provider.dart';
import 'screens/expense/expense_list_screen.dart';
import 'screens/expense/expense_category_list_screen.dart';
import 'screens/sale/sale_list_screen.dart';
import 'screens/sale/sale_category_list_screen.dart';
import 'screens/sale/credit_sale_list_screen.dart';
import 'screens/sale/financial_statement_list_screen.dart';
import 'screens/sale/financial_statement_generate_screen.dart';
import 'screens/sale/financial_statement_detail_screen.dart';
import 'screens/user/edit_profile_screen.dart';
import 'screens/user/change_password_screen.dart';

/// Debug switch: set to `true` to wipe the local database on every app
/// start, simulating a fresh install (onboarding screen shows again
/// instead of login/dashboard). Set back to `false` for normal use —
/// toggle freely, no other code changes needed.
const bool _debugResetDatabaseOnStart = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite (o pacote "puro") só suporta Android/iOS nativamente.
  // Em web/desktop é preciso trocar o databaseFactory global para uma
  // implementação FFI antes de qualquer acesso à base de dados.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android/iOS: mantém o databaseFactory por defeito do sqflite.

  if (_debugResetDatabaseOnStart) {
    await LocalDatabase.instance.resetDatabase();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localDatabase = LocalDatabase.instance;
    final userDao = UserDao(localDatabase);
    final userRepository = UserRepository(localDatabase, userDao);

    final customerDao = CustomerDao(localDatabase);
    final customerRepository = CustomerRepository(localDatabase, customerDao);

    final supplierDao = SupplierDao(localDatabase);
    final supplierRepository = SupplierRepository(localDatabase, supplierDao);

    final expenseDao = ExpenseDao(localDatabase);
    final expenseCategoryDao = ExpenseCategoryDao(localDatabase);
    final expenseRepository = ExpenseRepository(localDatabase, expenseDao, expenseCategoryDao);

    final saleDao = SaleDao(localDatabase);
    final saleCategoryDao = SaleCategoryDao(localDatabase);
    final saleInstallmentDao = SaleInstallmentDao(localDatabase);
    final salePaymentDao = SalePaymentDao(localDatabase);
    final saleRepository = SaleRepository(localDatabase, saleDao, saleCategoryDao, saleInstallmentDao, salePaymentDao);

    final financialStatementDao = FinancialStatementDao(localDatabase);
    final financialStatementRepository =
        FinancialStatementRepository(localDatabase, financialStatementDao);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider(userRepository)),
        ChangeNotifierProvider(create: (_) => CustomerProvider(customerRepository)),
        ChangeNotifierProvider(create: (_) => SupplierProvider(supplierRepository)),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(expenseRepository)),
        ChangeNotifierProvider(create: (_) => SaleProvider(saleRepository)),
        ChangeNotifierProvider(
          create: (_) => FinancialStatementProvider(financialStatementRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Mini',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routes: {
          '/onboarding': (_) => const OnboardingScreen(),
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
          '/customer': (_) => const CustomerListScreen(),
          '/supplier': (_) => const SupplierListScreen(),
          '/expense': (_) => const ExpenseListScreen(),
          '/expense-category': (_) => const ExpenseCategoryListScreen(),
          '/sale': (_) => const SaleListScreen(),
          '/sale-category': (_) => const SaleCategoryListScreen(),
          '/credit-sale': (_) => const CreditSaleListScreen(),
          '/sale/financial-statement': (_) => const FinancialStatementListScreen(),
          '/sale/financial-statement/generate': (_) =>
              const FinancialStatementGenerateScreen(),
          '/edit-profile': (_) => const EditProfileScreen(),
          '/change-password': (_) => const ChangePasswordScreen(),
        },
        home: const _StartupGate(),
      ),
    );
  }
}

/// Decides the initial screen by checking whether a user already
/// exists in the database. Shows a loading indicator while that
/// check resolves.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<void> _loadUserFuture;

  @override
  void initState() {
    super.initState();
    _loadUserFuture = context.read<UserProvider>().loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasUser = context.watch<UserProvider>().hasUser;
        return hasUser ? const LoginScreen() : const OnboardingScreen();
      },
    );
  }
}

