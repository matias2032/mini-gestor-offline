import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/database/local_database.dart';
import 'daos/user_dao.dart';
import 'repositories/user_repository.dart';
import 'providers/user_provider.dart';
import 'daos/business_unit_dao.dart';
import 'repositories/business_unit_repository.dart';
import 'providers/business_unit_provider.dart';
import 'daos/customer_dao.dart';
import 'repositories/customer_repository.dart';
import 'providers/customer_provider.dart';
import 'screens/user/onboarding_screen.dart';
import 'screens/user/welcome_screen.dart';
import 'screens/user/activation_screen.dart';
import 'screens/user/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'daos/supplier_dao.dart';
import 'repositories/supplier_repository.dart';
import 'providers/supplier_provider.dart';
import 'screens/supplier/supplier_list_screen.dart';
import 'daos/sale_dao.dart';
import 'repositories/sale_repository.dart';
import 'providers/sale_provider.dart';
import 'daos/financial_statement_dao.dart';
import 'repositories/financial_statement_repository.dart';
import 'providers/financial_statement_provider.dart';
import 'daos/expense_dao.dart';
import 'repositories/expense_repository.dart';
import 'providers/expense_provider.dart';
import 'screens/expense/expense_list_screen.dart';
import 'screens/sale/sale_list_screen.dart';
import 'screens/sale/sale_form_screen.dart';
import 'screens/sale/credit_sale_list_screen.dart';
import 'screens/sale/financial_statement_list_screen.dart';
import 'screens/sale/financial_statement_generate_screen.dart';
import 'screens/sale/financial_statement_detail_screen.dart';
import 'screens/user/edit_profile_screen.dart';
import 'screens/user/change_password_screen.dart';
import 'screens/business_unit/business_unit_management_screen.dart';
import 'screens/settings/backup_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'package:mini/l10n/app_localizations.dart';
import 'screens/splash/splash_screen.dart';
import 'providers/dashboard_provider.dart';


// Debug switch: set to true to wipe local database on every startup.
const bool _debugResetDatabaseOnStart = false;

// Single instance: MaterialApp can rebuild (theme/locale) without re-attaching a new observer.
final _resumeRouteObserver = ResumeRouteObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(ResumeLifecycleObserver());

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (kDebugMode && _debugResetDatabaseOnStart) {
    debugPrint('🧨 Apagando BD SQLite local (business_manager.db)...');
    await LocalDatabase.instance.resetDatabase();
    debugPrint('✅ BD apagada. Será recriada no primeiro acesso.');
  }

  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  runApp(MyApp(localeProvider: localeProvider));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.localeProvider});

  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    final localDatabase = LocalDatabase.instance;
    final userDao = UserDao(localDatabase);

// Repositories and DAOs initialization
    final businessUnitDao = BusinessUnitDao();
    final businessUnitRepository = BusinessUnitRepository(dao: businessUnitDao);
    final userRepository = UserRepository(localDatabase, userDao, businessUnitRepository);

    final customerDao = CustomerDao(localDatabase);
    final customerRepository = CustomerRepository(localDatabase, customerDao);

    final supplierDao = SupplierDao(localDatabase);
    final supplierRepository = SupplierRepository(localDatabase, supplierDao);

    final expenseDao = ExpenseDao(localDatabase);
    final expenseRepository = ExpenseRepository(localDatabase, expenseDao);

    final saleDao = SaleDao(localDatabase);
    final saleRepository = SaleRepository(localDatabase, saleDao, businessUnitDao);

    final financialStatementDao = FinancialStatementDao(localDatabase);
    final financialStatementRepository = FinancialStatementRepository(
      localDatabase,
      financialStatementDao,
      businessUnitDao,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
ChangeNotifierProvider.value(value: localeProvider),
ChangeNotifierProvider(create: (_) => UserProvider(userRepository)),

// BusinessUnitProvider must be initialized before dependent providers
        ChangeNotifierProvider(
          create: (_) => BusinessUnitProvider(
            repository: businessUnitRepository,
          )..loadUnits(),
        ),
        ChangeNotifierProxyProvider<BusinessUnitProvider, DashboardProvider>(
          create: (context) => DashboardProvider(
            saleRepository,
            context.read<BusinessUnitProvider>(),
          ),
          update: (_, businessUnitProvider, previous) =>
              previous ?? DashboardProvider(saleRepository, businessUnitProvider),
        ),

        ChangeNotifierProxyProvider<BusinessUnitProvider, CustomerProvider>(
          create: (context) => CustomerProvider(
            customerRepository,
            context.read<BusinessUnitProvider>(),
          ),
          update: (_, __, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<BusinessUnitProvider, SupplierProvider>(
          create: (context) => SupplierProvider(
            supplierRepository,
            context.read<BusinessUnitProvider>(),
          ),
          update: (_, __, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<BusinessUnitProvider, ExpenseProvider>(
          create: (context) => ExpenseProvider(
            expenseRepository,
            context.read<BusinessUnitProvider>(),
          ),
          update: (_, __, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<BusinessUnitProvider, SaleProvider>(
          create: (context) => SaleProvider(
            saleRepository,
            context.read<BusinessUnitProvider>(),
          ),
          update: (_, __, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<BusinessUnitProvider, FinancialStatementProvider>(
          create: (context) => FinancialStatementProvider(
            financialStatementRepository,
            context.read<BusinessUnitProvider>(),
          ),
          update: (_, __, previous) => previous!,
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) => MaterialApp(
          title: 'Mini',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: localeProvider.locale,
          navigatorObservers: [_resumeRouteObserver],
          routes: {
            '/activate': (_) => const ActivationScreen(),
            '/welcome': (_) => const WelcomeScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login': (_) => const LoginScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/customer': (_) => const CustomerListScreen(),
            '/supplier': (_) => const SupplierListScreen(),
            '/expense': (_) => const ExpenseListScreen(),
            '/sale': (_) => const SaleListScreen(),
            '/sale/new': (_) => const SaleFormScreen(),
            '/credit-sale': (_) => const CreditSaleListScreen(),
            '/sale/financial-statement': (_) => const FinancialStatementListScreen(),
            '/sale/financial-statement/generate': (_) =>
                const FinancialStatementGenerateScreen(),
            '/edit-profile': (_) => const EditProfileScreen(),
            '/change-password': (_) => const ChangePasswordScreen(),
            '/business-unit-management': (_) => const BusinessUnitManagementScreen(),
            '/settings/backup': (_) => const BackupScreen(),
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}