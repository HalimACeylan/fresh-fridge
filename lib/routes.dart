import 'package:flutter/material.dart';
import 'package:fridge_app/screens/welcome_login_screen.dart';
import 'package:fridge_app/screens/inside_fridge_screen.dart';
import 'package:fridge_app/screens/suggested_recipes_screen.dart';
import 'package:fridge_app/screens/scan_receipt_screen.dart';
import 'package:fridge_app/screens/recent_scan_results_screen.dart';
import 'package:fridge_app/screens/create_family_group_screen.dart';
import 'package:fridge_app/screens/home_manager_admin_screen.dart';
import 'package:fridge_app/screens/recipe_voting_screen.dart';
import 'package:fridge_app/screens/fridge_grid_screen.dart';
import 'package:fridge_app/screens/food_item_details_screen.dart';
import 'package:fridge_app/screens/recipe_preparation_guide_screen.dart';

class AppRoutes {
  static const String welcomeLogin = '/';
  static const String insideFridge = '/inside_fridge';
  static const String suggestedRecipes = '/suggested_recipes';
  static const String scanReceipt = '/scan_receipt';
  static const String recentScanResults = '/recent_scan_results';
  static const String createFamilyGroup = '/create_family_group';
  static const String homeManagerAdmin = '/home_manager_admin';
  static const String recipeVoting = '/recipe_voting';
  static const String fridgeGrid = '/fridge_grid';
  static const String foodItemDetails = '/food_item_details';
  static const String recipePreparation = '/recipe_preparation';

  static Map<String, WidgetBuilder> get routes => {
    welcomeLogin: (context) => const WelcomeLoginScreen(),
    insideFridge: (context) => const InsideFridgeScreen(),
    suggestedRecipes: (context) => const SuggestedRecipesScreen(),
    scanReceipt: (context) => const ScanReceiptScreen(),
    recentScanResults: (context) => const RecentScanResultsScreen(),
    createFamilyGroup: (context) => const CreateFamilyGroupScreen(),
    homeManagerAdmin: (context) => const HomeManagerAdminScreen(),
    recipeVoting: (context) => const RecipeVotingScreen(),
    fridgeGrid: (context) => const FridgeGridScreen(),
    foodItemDetails: (context) => const FoodItemDetailsScreen(),
    recipePreparation: (context) => const RecipePreparationGuideScreen(),
  };
}
