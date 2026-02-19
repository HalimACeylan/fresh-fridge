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
  const seedModeEnv = String.fromEnvironment(
    'FIREBASE_SEED_MODE',
    defaultValue: 'if-empty',
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await UserHouseholdService.instance.initialize();

    final seedMode = switch (seedModeEnv.toLowerCase()) {
      'overwrite' => 'overwrite',
      'skip' => 'skip',
      'clear' => 'clear',
      _ => 'if-empty',
    };

    final forceReseed = seedMode == 'overwrite';
    final seedIfEmpty = seedMode == 'if-empty';

    await FridgeService.instance.initialize(
      seedCloudIfEmpty: seedIfEmpty,
      forceReseed: forceReseed,
    );
    await ReceiptService.instance.initialize(
      seedCloudIfEmpty: seedIfEmpty,
      forceReseed: forceReseed,
    );

    if (seedMode == 'clear') {
      await FridgeService.instance.clearCloudForActiveHousehold();
      await ReceiptService.instance.clearCloudForActiveHousehold();
    }
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
