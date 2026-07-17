import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:receipto/firebase_options.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/reminder_engine.dart';

const String warrantyCheckTask = "warrantyCheckPeriodicTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environmental configuration
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    // Initialize Firebase
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {}

    // Initialize Supabase
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
    } catch (_) {}

    // Fetch active user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return true;
    }

    final container = ProviderContainer();
    // Initialize notifications
    await container.read(notificationServiceProvider).initialize(container);

    try {
      final engine = container.read(reminderEngineProvider);
      await engine.checkWarrantyReminders(
        currentUser.uid,
        currentUser.email,
        currentUser.displayName,
      );
    } catch (e) {
      if (kDebugMode) print('Error running background checks via reminder engine: $e');
    }

    return true;
  });
}

class BackgroundService {
  /// Registers the daily periodic task checks using Workmanager
  static void registerPeriodicTask() {
    Workmanager().registerPeriodicTask(
      "1",
      warrantyCheckTask,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
