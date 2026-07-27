import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:workmanager/workmanager.dart';
import 'package:receipto/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/reminder_engine.dart';

const String warrantyCheckTask = "warrantyCheckPeriodicTask";

/// Reliable environment loader targeting background isolates
Future<void> loadEnvReliably() async {
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[EnvLoad] Loaded via dotenv.load(.env)');
  } catch (e) {
    debugPrint('[EnvLoad] dotenv.load(.env) failed: $e. Trying manual loadString(.env)...');
    try {
      final content = await rootBundle.loadString('.env');
      final lines = const LineSplitter().convert(content);
      dotenv.env.addAll(const Parser().parse(lines));
      debugPrint('[EnvLoad] Loaded manually via .env');
    } catch (e2) {
      debugPrint('[EnvLoad] manual loadString(.env) failed: $e2. Trying manual loadString(assets/.env)...');
      try {
        final content = await rootBundle.loadString('assets/.env');
        final lines = const LineSplitter().convert(content);
        dotenv.env.addAll(const Parser().parse(lines));
        debugPrint('[EnvLoad] Loaded manually via assets/.env');
      } catch (e3) {
        debugPrint('[EnvLoad] All environment loading methods failed: $e3');
      }
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('Reminder triggered');
    debugPrint('[WorkManager] started: task=$taskName');

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_workmanager_run', DateTime.now().toLocal().toString());
      await prefs.setString('last_workmanager_status', 'RUNNING');
    } catch (e) {
      debugPrint('[WorkManager] SharedPreferences failed: $e');
    }
    
    // Load environmental configuration
    debugPrint('Loading dotenv');
    await loadEnvReliably();

    // Initialize Firebase
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      debugPrint('[WorkManager] Firebase initialized.');
    } catch (e) {
      debugPrint('[WorkManager] Firebase initialization error: $e');
    }

    // Initialize Supabase (with SharedPreferences fallback)
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? prefs?.getString('env_SUPABASE_URL');
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? prefs?.getString('env_SUPABASE_ANON_KEY');
      
      if (supabaseUrl != null && supabaseKey != null) {
        await sb.Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseKey,
        );
        debugPrint('[WorkManager] Supabase initialized successfully.');
      } else {
        throw Exception('Supabase URL or Anon Key is missing.');
      }
    } catch (e) {
      debugPrint('[WorkManager] Supabase initialization error: $e');
    }

    // Fetch active user with delay recovery checks
    fb.User? currentUser = fb.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Wait up to 3 seconds for session to restore asynchronously
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        currentUser = fb.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          debugPrint('[WorkManager] User session restored after ${i * 100}ms.');
          break;
        }
      }
    }

    String? userEmail = currentUser?.email;
    String? userUid = currentUser?.uid;

    if (userEmail == null || userEmail.isEmpty || userUid == null || userUid.isEmpty) {
      userEmail = prefs?.getString('last_logged_in_email');
      userUid = prefs?.getString('last_logged_in_uid');
      debugPrint('[WorkManager] Retrieved cached user credentials from SharedPreferences: email=$userEmail, uid=$userUid');
    }

    if (userUid == null || userUid.isEmpty) {
      debugPrint('No active authenticated user found');
      debugPrint('[WorkManager] cancelled: No active authenticated user found.');
      await prefs?.setString('last_workmanager_status', 'CANCELLED (No User)');
      return true;
    }
    debugPrint('active user found: $userUid');

    final container = ProviderContainer();
    // Initialize notifications
    await container.read(notificationServiceProvider).initialize(container);

    try {
      final engine = container.read(reminderEngineProvider);
      await engine.checkWarrantyReminders(
        userUid,
        userEmail,
        currentUser?.displayName,
      );
      await prefs?.setString('last_workmanager_status', 'SUCCESS');
      debugPrint('[WorkManager] finished: task=$taskName successfully executed.');
    } catch (e) {
      await prefs?.setString('last_workmanager_status', 'FAILED: $e');
      debugPrint('[WorkManager] failed: task=$taskName error=$e');
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
