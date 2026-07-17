import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:receipto/app/app.dart';
import 'package:receipto/firebase_options.dart';
import 'package:receipto/core/services/notification_service.dart';
import 'package:receipto/core/services/background_service.dart';

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

  // Initialize Notification Service
  final notificationService = container.read(notificationServiceProvider);
  await notificationService.initialize(container);
  await notificationService.requestPermission();

  // Initialize Workmanager
  Workmanager().initialize(
    callbackDispatcher,
  );
  BackgroundService.registerPeriodicTask();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ReceiptoApp(),
    ),
  );
}