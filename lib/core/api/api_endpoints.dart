import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();
  static const bool isPhysicalDevice = true;

  static const String computerIpAdress = "192.168.1.7";

  static const int port = 5000;

  /// Server root (no `/api`) — used for static assets such as /uploads images.
  static String get serverAddress {
    if (isPhysicalDevice) {
      return "http://$computerIpAdress:$port";
    }
    if (kIsWeb) {
      return "http://localhost:$port";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:$port";
    } else if (Platform.isIOS) {
      return "http://localhost:$port";
    } else {
      return "http://localhost:$port";
    }
  }

  /// REST API root — backend mounts all routes under `/api`.
  static String get baseUrl => "$serverAddress/api";

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth endpoints
  static String get loginUser => '$baseUrl/auth/login';
  static String get registerUser => '$baseUrl/auth/register';
  static String get googleAuth => '$baseUrl/auth/google';
  static String get logout => '$baseUrl/auth/logout';
  static String get getCurrentUser => '$baseUrl/auth/me';
  static String get updateUser => '$baseUrl/auth/update-profile';
  static String get changePassword => '$baseUrl/auth/change-password';
  static String get requestPasswordReset => '$baseUrl/auth/forgot-password';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get resetPassword => '$baseUrl/auth/reset-password';

  // Catalog endpoints (categories + brands: global presets + user-owned)
  static String get categories => '$baseUrl/categories';
  static String get brands => '$baseUrl/brands';

  // Wardrobe (closet furniture) designer endpoints
  static String get closetLayout => '$baseUrl/closet';
  static String get saveClosetLayout => '$baseUrl/closet/save';

  /// DELETE a single wardrobe by its layout id.
  static String closetLayoutById(String layoutId) => '$baseUrl/closet/$layoutId';

  // Outfit (assemble / ensemble) endpoints
  static String get outfits => '$baseUrl/outfits';
  static String get createOutfit => '$outfits/plan';

  /// Mark an outfit worn (bumps each item's wear count).
  static String wearOutfit(String outfitId) => '$outfits/wear/$outfitId';

  /// Single outfit (GET / PATCH / DELETE).
  static String outfitById(String outfitId) => '$outfits/$outfitId';

  // Plan (scheduled outfit) endpoints
  static String get plans => '$baseUrl/plans';

  /// Single plan (GET / PATCH / DELETE).
  static String planById(String planId) => '$plans/$planId';

  // Analytics endpoints
  static String get analyticsOverview => '$baseUrl/analytics/overview';

  // Wardrobe endpoints
  static String get wardrobe => '$baseUrl/wardrobe';
  static String get addWardrobeItem => '$wardrobe/add';
  static String get recentWardrobeItems => '$wardrobe/recent';
  static String get favoriteWardrobeItems => '$wardrobe/favorites';

  /// Single item (GET / DELETE).
  static String wardrobeItem(String itemId) => '$wardrobe/$itemId';

  /// PATCH endpoint for toggling an item's favourite flag.
  static String toggleWardrobeFavorite(String itemId) => '$wardrobe/$itemId/favorite';

  /// PATCH endpoint to increment an item's wear count.
  static String markWornWardrobeItem(String itemId) => '$wardrobe/$itemId/wear';
}
