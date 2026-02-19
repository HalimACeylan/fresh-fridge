import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fridge_app/firebase_options.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'package:fridge_app/services/receipt_service.dart';
import 'package:fridge_app/services/user_household_service.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseAndServices();
  runApp(const FridgeApp());
}

Future<void> _initializeFirebaseAndServices() async {
  const seedMode = String.fromEnvironment(
    'FIREBASE_SEED_MODE',
    defaultValue: 'if-empty',
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await UserHouseholdService.instance.initialize();

    final forceReseed = seedMode == 'overwrite';
    final seedIfEmpty = seedMode != 'skip';

    await FridgeService.instance.initialize(
      seedCloudIfEmpty: seedIfEmpty,
      forceReseed: forceReseed,
    );
    await ReceiptService.instance.initialize(
      seedCloudIfEmpty: seedIfEmpty,
      forceReseed: forceReseed,
    );
  } catch (_) {
    // App continues with in-memory sample data when Firebase is unavailable.
  }
}

class FridgeApp extends StatelessWidget {
  const FridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FridgeApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF13EC13),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.workSansTextTheme(),
      ),
      initialRoute: AppRoutes.welcomeLogin,
      routes: AppRoutes.routes,
    );
  }
}
