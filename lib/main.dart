import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Keep the native (OS) splash on screen until the startup gate restores the
  // session and routes to the first real screen — no Flutter splash needed.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Initialize Hive for local storage
  final hiveService = HiveService();
  await hiveService.initialize();

  // Prepare local notifications (timezone DB + channels) for plan reminders.
  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
