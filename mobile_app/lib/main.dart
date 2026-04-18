import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verify_otp_screen.dart';
import 'screens/home_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/features_screen.dart';
import 'screens/reports_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/family_provider.dart';
import 'providers/report_provider.dart';
import 'providers/bills_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/budget_setup_screen.dart';
import 'screens/budget/simple_budget_setup.dart';
import 'screens/budget_dashboard_screen.dart';
import 'screens/category_management_screen.dart';
import 'screens/savings/savings_goal_list_screen.dart';
import 'screens/family/family_dashboard_screen.dart';
import 'screens/family/family_setup_screen.dart';
import 'screens/family/family_management_screen.dart';
import 'screens/notification_inbox_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/main_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/all_users_screen.dart';
import 'screens/admin/all_transactions_screen.dart';
import 'screens/admin/system_log_screen.dart';
import 'theme/app_theme.dart';

import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      // For Web, Firebase initialization often requires options.
      // We wrap it in a try-catch to ensure the app still runs even if initialization fails.
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Firebase/Notification initialization skipped or failed: $e');
    }

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        print('FlutterError: ${details.exception}');
        print('Stack trace: ${details.stack}');
      }
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => BudgetProvider()),
          ChangeNotifierProvider(create: (_) => SavingsProvider()),
          ChangeNotifierProvider(create: (_) => FamilyProvider()),
          ChangeNotifierProvider(create: (_) => ReportProvider()),
          ChangeNotifierProvider(create: (_) => BillsProvider()),
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stackTrace) {
    if (kDebugMode) {
      print('Caught error: $error');
      print('Stack trace: $stackTrace');
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool>? _authFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future once at startup
    _authFuture = Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wise Wallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return FutureBuilder<bool>(
            future: _authFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primaryStart),
                  ),
                );
              }
              
              if (auth.isAuthenticated) {
                final String role = (auth.user?['role'] ?? 'user').toString().trim().toLowerCase();
                if (role == 'admin') {
                  return const AdminDashboardScreen();
                } else {
                  return const MainScreen();
                }
              }
              
              return const LoginScreen();
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/verify': (context) => const VerifyOtpScreen(),
        '/main': (context) => const MainScreen(),
        '/home': (context) => const MainScreen(), 
        '/transactions': (context) => const TransactionListScreen(),
        '/add-transaction': (context) => const AddTransactionScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/features': (context) => const FeaturesScreen(),
        '/budget-setup': (context) => const SimpleBudgetSetup(),
        '/budget-setup-advanced': (context) => const BudgetSetupScreen(),
        '/budget-dashboard': (context) => const BudgetDashboardScreen(),
        '/categories': (context) => const CategoryManagementScreen(),
        '/savings': (context) => const SavingsGoalListScreen(),
        '/family': (context) => const FamilyDashboardScreen(),
        '/family-setup': (context) => const FamilySetupScreen(),
        '/family-management': (context) => const FamilyManagementScreen(),
        '/reports': (context) => ReportsScreen(),
        '/notifications': (context) => const NotificationInboxScreen(),
        '/bills': (context) => const BillsListScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin/users': (context) => const AllUsersScreen(),
        '/admin/transactions': (context) => const AllTransactionsScreen(),
        '/admin/logs': (context) => const SystemLogScreen(),
      },
    );
  }
}

