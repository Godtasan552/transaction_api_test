// services/universal_storage_service.dart
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'mobile_storage_service.dart';
import 'web_service.dart';

/// Universal Storage Service - ตัวกลางที่จัดการการเลือกใช้ storage
/// สำหรับ Web และ Mobile โดยอัตโนมัติ
class UniversalStorageService {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;

  // Initialize storage based on platform
  static Future<void> init() async {
    try {
      if (isWeb) {
        await WebStorageService.init();
        debugPrint('✅ Universal Storage initialized for Web');
      } else {
        await MobileStorageService.init();
        debugPrint('✅ Universal Storage initialized for Mobile');
      }
    } catch (e) {
      debugPrint('❌ Error initializing Universal Storage: $e');
      rethrow;
    }
  }

  // ==================== TOKEN MANAGEMENT ====================
  
  static Future<bool> saveToken(String token) async {
    if (isWeb) {
      return await WebStorageService.saveToken(token);
    } else {
      return await MobileStorageService.saveToken(token);
    }
  }

  static String? getToken() {
    if (isWeb) {
      return WebStorageService.getToken();
    } else {
      return MobileStorageService.getToken();
    }
  }

  static Future<bool> deleteToken() async {
    if (isWeb) {
      return await WebStorageService.deleteToken();
    } else {
      return await MobileStorageService.deleteToken();
    }
  }

  static bool hasToken() {
    if (isWeb) {
      return WebStorageService.hasToken();
    } else {
      return MobileStorageService.hasToken();
    }
  }

  // ==================== USER DATA MANAGEMENT ====================
  
  static Future<bool> saveUser(Map<String, dynamic> userData) async {
    if (isWeb) {
      return await WebStorageService.saveUser(userData);
    } else {
      return await MobileStorageService.saveUser(userData);
    }
  }

  static Map<String, dynamic>? getUser() {
    if (isWeb) {
      return WebStorageService.getUser();
    } else {
      return MobileStorageService.getUser();
    }
  }

  static Future<bool> deleteUser() async {
    if (isWeb) {
      return await WebStorageService.deleteUser();
    } else {
      return await MobileStorageService.deleteUser();
    }
  }

  static bool hasUser() {
    if (isWeb) {
      return WebStorageService.hasUser();
    } else {
      return MobileStorageService.hasUser();
    }
  }

  // ==================== TRANSACTION DATA MANAGEMENT ====================
  
  static Future<bool> saveTransactions(List<Map<String, dynamic>> transactions) async {
    if (isWeb) {
      return await WebStorageService.saveTransactions(transactions);
    } else {
      return await MobileStorageService.saveTransactions(transactions);
    }
  }

  static List<Map<String, dynamic>> getTransactions() {
    if (isWeb) {
      return WebStorageService.getTransactions();
    } else {
      return MobileStorageService.getTransactions();
    }
  }

  static Future<bool> addTransaction(Map<String, dynamic> transaction) async {
    if (isWeb) {
      return await WebStorageService.addTransaction(transaction);
    } else {
      return await MobileStorageService.addTransaction(transaction);
    }
  }

  static Future<bool> updateTransaction(String uuid, Map<String, dynamic> updatedTransaction) async {
    if (isWeb) {
      return await WebStorageService.updateTransaction(uuid, updatedTransaction);
    } else {
      return await MobileStorageService.updateTransaction(uuid, updatedTransaction);
    }
  }

  static Future<bool> deleteTransaction(String uuid) async {
    if (isWeb) {
      return await WebStorageService.deleteTransaction(uuid);
    } else {
      return await MobileStorageService.deleteTransaction(uuid);
    }
  }

  static Map<String, dynamic>? getTransactionByUuid(String uuid) {
    if (isWeb) {
      return WebStorageService.getTransactionByUuid(uuid);
    } else {
      return MobileStorageService.getTransactionByUuid(uuid);
    }
  }

  static List<Map<String, dynamic>> getTransactionsByWallet(String walletUuid) {
    if (isWeb) {
      return WebStorageService.getTransactionsByWallet(walletUuid);
    } else {
      return MobileStorageService.getTransactionsByWallet(walletUuid);
    }
  }

  static Future<bool> clearTransactions() async {
    if (isWeb) {
      return await WebStorageService.clearTransactions();
    } else {
      return await MobileStorageService.clearTransactions();
    }
  }

  // ==================== GENERAL METHODS ====================
  
  static Future<bool> clearAll() async {
    if (isWeb) {
      return await WebStorageService.clearAll();
    } else {
      return await MobileStorageService.clearAll();
    }
  }

  static Set<String> getAllKeys() {
    if (isWeb) {
      return WebStorageService.getAllKeys();
    } else {
      return MobileStorageService.getAllKeys();
    }
  }

  static bool isEmpty() {
    if (isWeb) {
      return WebStorageService.isEmpty();
    } else {
      return MobileStorageService.isEmpty();
    }
  }

  // ==================== UTILITY METHODS ====================
  
  static Future<bool> saveData(String key, dynamic data) async {
    if (isWeb) {
      return await WebStorageService.saveData(key, data);
    } else {
      return await MobileStorageService.saveData(key, data);
    }
  }

  static T? getData<T>(String key) {
    if (isWeb) {
      return WebStorageService.getData<T>(key);
    } else {
      return MobileStorageService.getData<T>(key);
    }
  }

  static Future<bool> deleteData(String key) async {
    if (isWeb) {
      return await WebStorageService.deleteData(key);
    } else {
      return await MobileStorageService.deleteData(key);
    }
  }

  static bool hasKey(String key) {
    if (isWeb) {
      return WebStorageService.hasKey(key);
    } else {
      return MobileStorageService.hasKey(key);
    }
  }

  // ==================== PLATFORM INFORMATION ====================
  
  static String getPlatformInfo() {
    if (isWeb) {
      return WebStorageService.getPlatformInfo();
    } else {
      return MobileStorageService.getPlatformInfo();
    }
  }

  static void printStorageInfo() {
    debugPrint('=====================================');
    debugPrint('📱 UNIVERSAL STORAGE SERVICE DEBUG INFO');
    debugPrint('=====================================');
    debugPrint('Current Platform: ${getPlatformInfo()}');
    debugPrint('Is Web: $isWeb');
    debugPrint('Is Mobile: $isMobile');
    
    if (isWeb) {
      WebStorageService.printStorageInfo();
    } else {
      MobileStorageService.printStorageInfo();
    }
  }
}