// services/mobile_storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Mobile Storage Service - จัดการ storage สำหรับ Flutter Mobile (iOS/Android)
/// ใช้ Hive ซึ่งเป็น NoSQL database ที่เร็วและเบาสำหรับ Flutter
class MobileStorageService {
  static const String _boxName = 'auth_box';
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _transactionKey = 'transactions_data';

  static Box? _hiveBox;

  // Initialize Hive box for Mobile
  static Future<void> init() async {
    try {
      _hiveBox = await Hive.openBox(_boxName);
      debugPrint('✅ Mobile Storage Service initialized (Hive)');
    } catch (e) {
      debugPrint('❌ Error initializing Mobile Storage Service: $e');
      rethrow;
    }
  }

  // Ensure storage is initialized
  static void _ensureInitialized() {
    if (_hiveBox == null) {
      throw Exception('Hive box not initialized. Call init() first.');
    }
  }

  // ==================== TOKEN MANAGEMENT ====================

  static Future<bool> saveToken(String token) async {
    try {
      _ensureInitialized();
      await _hiveBox!.put(_tokenKey, token);
      debugPrint('🔐 Token saved (Mobile): Success');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving token (Mobile): $e');
      return false;
    }
  }

  static String? getToken() {
    try {
      _ensureInitialized();
      final token = _hiveBox!.get(_tokenKey);
      debugPrint('🔐 Token retrieved (Mobile): ${token != null ? 'Found' : 'Not found'}');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting token (Mobile): $e');
      return null;
    }
  }

  static Future<bool> deleteToken() async {
    try {
      _ensureInitialized();
      await _hiveBox!.delete(_tokenKey);
      debugPrint('🔐 Token deleted (Mobile): Success');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting token (Mobile): $e');
      return false;
    }
  }

  static bool hasToken() {
    try {
      _ensureInitialized();
      final hasToken = _hiveBox!.containsKey(_tokenKey);
      final token = _hiveBox!.get(_tokenKey);
      final isValid = hasToken && token != null && token.toString().isNotEmpty;
      debugPrint('🔐 Has valid token (Mobile): $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking token (Mobile): $e');
      return false;
    }
  }

  // ==================== USER DATA MANAGEMENT ====================

  static Future<bool> saveUser(Map<String, dynamic> userData) async {
    try {
      _ensureInitialized();
      final userJson = jsonEncode(userData);
      await _hiveBox!.put(_userKey, userJson);
      debugPrint('👤 User data saved (Mobile): Success');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving user data (Mobile): $e');
      return false;
    }
  }

  static Map<String, dynamic>? getUser() {
    try {
      _ensureInitialized();
      final userJson = _hiveBox!.get(_userKey);
      
      if (userJson != null && userJson.toString().isNotEmpty) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        debugPrint('👤 User data retrieved (Mobile): ${userData['firstName']} ${userData['lastName']}');
        return userData;
      }
      
      debugPrint('👤 No user data found (Mobile)');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data (Mobile): $e');
      return null;
    }
  }

  static Future<bool> deleteUser() async {
    try {
      _ensureInitialized();
      await _hiveBox!.delete(_userKey);
      debugPrint('👤 User data deleted (Mobile): Success');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting user data (Mobile): $e');
      return false;
    }
  }

  static bool hasUser() {
    try {
      _ensureInitialized();
      final hasUser = _hiveBox!.containsKey(_userKey);
      final userJson = _hiveBox!.get(_userKey);
      final isValid = hasUser && userJson != null && userJson.toString().isNotEmpty;
      debugPrint('👤 Has valid user data (Mobile): $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking user data (Mobile): $e');
      return false;
    }
  }

  // ==================== TRANSACTION DATA MANAGEMENT ====================

  static Future<bool> saveTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      _ensureInitialized();
      final transactionsJson = jsonEncode(transactions);
      await _hiveBox!.put(_transactionKey, transactionsJson);
      debugPrint('💰 Transactions saved (Mobile): Success (${transactions.length} items)');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving transactions (Mobile): $e');
      return false;
    }
  }

  static List<Map<String, dynamic>> getTransactions() {
    try {
      _ensureInitialized();
      final transactionsJson = _hiveBox!.get(_transactionKey);
      
      if (transactionsJson != null && transactionsJson.toString().isNotEmpty) {
        final decoded = jsonDecode(transactionsJson) as List<dynamic>;
        final transactions = decoded.cast<Map<String, dynamic>>();
        debugPrint('💰 Transactions retrieved (Mobile): ${transactions.length} items');
        return transactions;
      }
      
      debugPrint('💰 No transactions found (Mobile)');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting transactions (Mobile): $e');
      return [];
    }
  }

  static Future<bool> addTransaction(Map<String, dynamic> transaction) async {
    try {
      final transactions = getTransactions();
      transactions.add(transaction);
      final result = await saveTransactions(transactions);
      debugPrint('💰 Transaction added (Mobile): ${result ? 'Success' : 'Failed'} - ${transaction['name']}');
      return result;
    } catch (e) {
      debugPrint('❌ Error adding transaction (Mobile): $e');
      return false;
    }
  }

  static Future<bool> updateTransaction(String uuid, Map<String, dynamic> updatedTransaction) async {
    try {
      final transactions = getTransactions();
      final index = transactions.indexWhere((t) => t['uuid'] == uuid);
      
      if (index != -1) {
        transactions[index] = updatedTransaction;
        final result = await saveTransactions(transactions);
        debugPrint('💰 Transaction updated (Mobile): ${result ? 'Success' : 'Failed'} - ${updatedTransaction['name']}');
        return result;
      }
      
      debugPrint('💰 Transaction not found for update: $uuid');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating transaction (Mobile): $e');
      return false;
    }
  }

  static Future<bool> deleteTransaction(String uuid) async {
    try {
      final transactions = getTransactions();
      final initialCount = transactions.length;
      transactions.removeWhere((t) => t['uuid'] == uuid);
      
      if (transactions.length < initialCount) {
        final result = await saveTransactions(transactions);
        debugPrint('💰 Transaction deleted (Mobile): ${result ? 'Success' : 'Failed'} - $uuid');
        return result;
      }
      
      debugPrint('💰 Transaction not found for deletion: $uuid');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting transaction (Mobile): $e');
      return false;
    }
  }

  static Map<String, dynamic>? getTransactionByUuid(String uuid) {
    try {
      final transactions = getTransactions();
      for (final transaction in transactions) {
        if (transaction['uuid'] == uuid) {
          debugPrint('💰 Transaction found by UUID (Mobile): ${transaction['name']}');
          return transaction;
        }
      }
      debugPrint('💰 Transaction not found by UUID: $uuid');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting transaction by UUID (Mobile): $e');
      return null;
    }
  }

  static List<Map<String, dynamic>> getTransactionsByWallet(String walletUuid) {
    try {
      final transactions = getTransactions();
      final walletTransactions = transactions.where((t) => t['wallet'] == walletUuid).toList();
      debugPrint('💰 Wallet transactions retrieved (Mobile): ${walletTransactions.length} items for wallet $walletUuid');
      return walletTransactions;
    } catch (e) {
      debugPrint('❌ Error getting transactions by wallet (Mobile): $e');
      return [];
    }
  }

  static Future<bool> clearTransactions() async {
    try {
      _ensureInitialized();
      await _hiveBox!.delete(_transactionKey);
      debugPrint('💰 Transactions cleared (Mobile): Success');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing transactions (Mobile): $e');
      return false;
    }
  }

  // ==================== GENERAL METHODS ====================

  static Future<bool> clearAll() async {
    try {
      _ensureInitialized();
      await _hiveBox!.clear();
      debugPrint('🧹 All data cleared (Mobile): Success');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing all data (Mobile): $e');
      return false;
    }
  }

  static Set<String> getAllKeys() {
    try {
      _ensureInitialized();
      final keys = _hiveBox!.keys.cast<String>().toSet();
      debugPrint('🔑 All keys (Mobile): $keys');
      return keys;
    } catch (e) {
      debugPrint('❌ Error getting all keys (Mobile): $e');
      return <String>{};
    }
  }

  static bool isEmpty() {
    try {
      _ensureInitialized();
      final isEmpty = _hiveBox!.keys.isEmpty;
      debugPrint('📦 Storage is empty (Mobile): $isEmpty');
      return isEmpty;
    } catch (e) {
      debugPrint('❌ Error checking if storage is empty (Mobile): $e');
      return true;
    }
  }

  // ==================== UTILITY METHODS ====================

  static Future<bool> saveData(String key, dynamic data) async {
    try {
      _ensureInitialized();
      await _hiveBox!.put(key, data);
      debugPrint('💾 Generic data saved (Mobile): Success for key $key');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving data for key $key (Mobile): $e');
      return false;
    }
  }

  static T? getData<T>(String key) {
    try {
      _ensureInitialized();
      final value = _hiveBox!.get(key);
      
      if (value is T) {
        debugPrint('💾 Generic data retrieved (Mobile) for key $key: ${value.runtimeType}');
        return value;
      }
      
      debugPrint('💾 No data found for key $key or wrong type (Mobile)');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting data for key $key (Mobile): $e');
      return null;
    }
  }

  static Future<bool> deleteData(String key) async {
    try {
      _ensureInitialized();
      await _hiveBox!.delete(key);
      debugPrint('💾 Data deleted (Mobile) for key $key: Success');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting data for key $key (Mobile): $e');
      return false;
    }
  }

  static bool hasKey(String key) {
    try {
      _ensureInitialized();
      final hasKey = _hiveBox!.containsKey(key);
      debugPrint('🔑 Key $key exists (Mobile): $hasKey');
      return hasKey;
    } catch (e) {
      debugPrint('❌ Error checking key $key (Mobile): $e');
      return false;
    }
  }

  // ==================== PLATFORM INFORMATION ====================

  static String getPlatformInfo() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'iOS (Hive)';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Android (Hive)';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'Windows (Hive)';
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return 'macOS (Hive)';
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return 'Linux (Hive)';
    }
    return 'Unknown Mobile Platform (Hive)';
  }

  static void printStorageInfo() {
    debugPrint('=====================================');
    debugPrint('📱 MOBILE STORAGE SERVICE DEBUG INFO');
    debugPrint('=====================================');
    debugPrint('Platform: ${getPlatformInfo()}');
    debugPrint('Storage initialized: ${_hiveBox != null}');
    debugPrint('Has token: ${hasToken()}');
    debugPrint('Has user: ${hasUser()}');
    debugPrint('All keys: ${getAllKeys()}');
    debugPrint('Storage empty: ${isEmpty()}');
    debugPrint('=====================================');
  }
}