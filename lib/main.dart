import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform defaults
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Emulator connectivity (set to true with --dart-define=USE_FIREBASE_EMULATOR=true for offline local testing)
  const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
  if (useEmulator) {
    const emulatorHost = kIsWeb ? 'localhost' : '127.0.0.1';
    try {
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      debugPrint('Connected to Firebase Emulator Suite at $emulatorHost:9099 (Auth) and $emulatorHost:8080 (Firestore)');
    } catch (e) {
      debugPrint('Emulator setup notice: $e');
    }
  }

  // Enable offline cache persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    const ProviderScope(
      child: NexusSaaSApp(),
    ),
  );
}

class NexusSaaSApp extends ConsumerWidget {
  const NexusSaaSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Nexus SaaS - Multi-Tenant Workspace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
