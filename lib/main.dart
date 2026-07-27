import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:receipto/app/app.dart';
import 'package:receipto/firebase_options.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/background_service.dart';
import 'package:receipto/core/services/email_service.dart';
import 'package:receipto/core/services/battery_optimization_service.dart';
import 'package:receipto/core/services/warranty_database_service.dart';
import 'package:receipto/core/services/receipt_database_service.dart';
import 'package:receipto/app/config/routes.dart';
import 'package:receipto/features/notifications/data/services/notification_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Riverpod ProviderContainer
  final container = ProviderContainer();

  // Cache environment credentials for background isolates
  try {
    await container.read(emailServiceProvider).cacheEnvCredentials();
  } catch (e) {
    debugPrint('[main] Error caching credentials: $e');
  }

  // Initialize Notification Service
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize(container);
  await notificationService.requestPermission();

  // Initialize Workmanager
  Workmanager().initialize(callbackDispatcher);
  BackgroundService.registerPeriodicTask();
  debugPrint('[main] WorkManager initialized.');

  // Listen to Auth changes to run startup notification synchronization
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (user.email != null && user.email!.isNotEmpty) {
          await prefs.setString('last_logged_in_email', user.email!);
          await prefs.setString('last_logged_in_uid', user.uid);
          debugPrint('[main.dart] Cached active user email to SharedPreferences: ${user.email}');
        }
      } catch (e) {
        debugPrint('[main.dart] SharedPreferences cache failed: $e');
      }

      debugPrint('[Startup] User detected: ${user.uid}. Starting notification synchronization...');
      try {
        final dbWarrs = await container.read(warrantyDatabaseServiceProvider).fetchAllWarranties(user.uid);
        final dbReceiptsService = container.read(receiptDatabaseServiceProvider);
        final activeReceipts = await dbReceiptsService.fetchAllReceipts(userId: user.uid);
        final activeReceiptIds = activeReceipts.map((r) => r['id'].toString()).toSet();
        final activeWarranties = dbWarrs.where((w) => activeReceiptIds.contains(w.receiptId)).toList();

        await container.read(notificationSchedulerProvider).syncWarranties(activeWarranties);

        // Show battery optimization prompt once after user is authenticated
        // Use a short delay so the UI is fully mounted before showing a dialog
        await Future.delayed(const Duration(seconds: 2));
        final context = container.read(routerProvider).routerDelegate.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          await BatteryOptimizationService.checkAndPromptIfNeeded(context);
        }
      } catch (e) {
        debugPrint('[Startup] Error during startup notification sync: $e');
      }
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ReceiptoApp(),
    ),
  );
}