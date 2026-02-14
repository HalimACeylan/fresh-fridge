import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const FridgeApp());
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
