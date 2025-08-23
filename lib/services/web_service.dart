// services/web_storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web Storage Service - จัดการ storage สำหรับ Flutter Web
/// ใช้ SharedPreferences ซึ่งจะทำงานผ่าน localStorage ใน browser
class WebStorageService {
  static const String _boxName = 'auth_box';
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _transactionKey = 'transactions_data';

  static SharedPreferences? _sharedPrefs;

  // Initialize SharedPreferences for Web
  static Future<void> init() async {
    try {
      _sharedPrefs = await SharedPreferences.getInstance();
      debugPrint('✅ Web Storage Service initialized (SharedPreferences)');
    } catch (e) {
      debugPrint('❌ Error initializing Web Storage Service: $e');
      rethrow;
    }
  }

  // Ensure storage is initialized
  static void _ensureInitialized() {
    if (_sharedPrefs == null) {
      throw Exception('SharedPreferences not initialized. Call init() first.');
    }
  }

  // ==================== TOKEN MANAGEMENT ====================

  static Future<bool> saveToken(String token) async {
    try {
      _ensureInitialized();
      final result = await _sharedPrefs!.setString(_tokenKey, token);
      debugPrint('🔐 Token saved (Web): ${result ? 'Success' : 'Failed'}');
      return result;
    } catch (e) {
      debugPrint('❌ Error saving token (Web): $e');
      return false;
    }
  }

  static String? getToken() {
    try {
      _ensureInitialized();
      final token = _sharedPrefs!.getString(_tokenKey);
      debugPrint('🔐 Token retrieved (Web): ${token != null ? 'Found' : 'Not found'}');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting token (Web): $e');
      return null;
    }
  }

  static Future<bool> deleteToken() async {
    try {
      _ensureInitialized();
      final result = await _sharedPrefs!.remove(_tokenKey);
      debugPrint('🔐 Token deleted (Web): ${result ? 'Success' : 'Failed'}');
      return result;
    } catch (e) {
      debugPrint('❌ Error deleting token (Web): $e');
      return false;
    }
  }

  static bool hasToken() {
    try {
      _ensureInitialized();
      final hasToken = _sharedPrefs!.containsKey(_tokenKey);
      final token = _sharedPrefs!.getString(_tokenKey);
      final isValid = hasToken && token != null && token.isNotEmpty;
      debugPrint('🔐 Has valid token (Web): $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking token (Web): $e');
      return false;
    }
  }

  // ==================== USER DATA MANAGEMENT ====================

  static Future<bool> saveUser(Map<String, dynamic> userData) async {
    try {
      _ensureInitialized();
      final userJson = jsonEncode(userData);
      final result = await _sharedPrefs!.setString(_userKey, userJson);
      debugPrint('👤 User data saved (Web): ${result ? 'Success' : 'Failed'}');
      return result;
    } catch (e) {
      debugPrint('❌ Error saving user data (Web): $e');
      return false;
    }
  }

  static Map<String, dynamic>? getUser() {
    try {
      _ensureInitialized();
      final userJson = _sharedPrefs!.getString(_userKey);
      
      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        debugPrint('👤 User data retrieved (Web): ${userData['firstName']} ${userData['lastName']}');
        return userData;
      }
      
      debugPrint('👤 No user data found (Web)');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data (Web): $e');
      return null;
    }
  }

  static Future<bool> deleteUser() async {
    try {
      _ensureInitialized();
      final result = await _sharedPrefs!.remove(_userKey);
      debugPrint('👤 User data deleted (Web): ${result ? 'Success' : 'Failed'}');
      return result;
    } catch (e) {
      debugPrint('❌ Error deleting user data (Web): $e');
      return false;
    }
  }

  static bool hasUser() {
    try {
      _ensureInitialized();
      final hasUser = _sharedPrefs!.containsKey(_userKey);
      final userJson = _sharedPrefs!.getString(_userKey);
      final isValid = hasUser && userJson != null && userJson.isNotEmpty;
      debugPrint('👤 Has valid user data (Web): $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking user data (Web): $e');
      return false;
    }
  }

  // ==================== TRANSACTION DATA MANAGEMENT ====================

  static Future<bool> saveTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      _ensureInitialized();
      final transactionsJson = jsonEncode(transactions);
      final result = await _sharedPrefs!.setString(_transactionKey, transactionsJson);
      debugPrint('💰 Transactions saved (Web): ${result ? 'Success' : 'Failed'} (${transactions.length} items)');
      return result;
    } catch (e) {
      debugPrint('❌ Error saving transactions (Web): $e');
      return false;
    }
  }

  static List<Map<String, dynamic>> getTransactions() {
    try {
      _ensureInitialized();
      final transactionsJson = _sharedPrefs!.getString(_transactionKey);
      
      if (transactionsJson != null && transactionsJson.isNotEmpty) {
        final decoded = jsonDecode(transactionsJson) as List<dynamic>;
        final transactions = decoded.cast<Map<String, dynamic>>();
        debugPrint('💰 Transactions retrieved (Web): ${transactions.length} items');
        return transactions;
      }
      
      debugPrint('💰 No transactions found (Web)');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting transactions (Web): $e');
      return [];
    }
  }

  static Future<bool> addTransaction(Map<String, dynamic> transaction) async {
    try {
      final transactions = getTransactions();
      transactions.add(transaction);
      final result = await saveTransactions(transactions);
      debugPrint('💰 Transaction added (Web): ${result ? 'Success' : 'Failed'} - ${transaction['name']}');
      return result;
    } catch (e) {
      debugPrint('❌ Error adding transaction (Web): $e');
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
        debugPrint('💰 Transaction updated (Web): ${result ? 'Success' : 'Failed'} - ${updatedTransaction['name']}');
        return result;
      }
      
      debugPrint('💰 Transaction not found for update: $uuid');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating transaction (Web): $e');
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
        debugPrint('💰 Transaction deleted (Web): ${result ? 'Success' : 'Failed'} - $uuid');
        return result;
      }
      
      debugPrint('💰 Transaction not found for deletion: $uuid');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting transaction (Web): $e');
      return false;
    }
  }

  static Map<String, dynamic>? getTransactionByUuid(String uuid) {
    try {
      final transactions = getTransactions();
      for (final transaction in transactions) {
        if (transaction['uuid'] == uuid) {
          debugPrint('💰 Transaction found by UUID (Web): ${transaction['name']}');
          return transaction;
        }
      }
      debugPrint('💰 Transaction not found by UUID: $uuid');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting transaction by UUID (Web): $e');
      return null;
    }
  }

  static List<Map<String, dynamic>> getTransactionsByWallet(String walletUuid) {
    try {
      final transactions = getTransactions();
      final walletTransactions = transactions.where((t) => t['wallet'] == walletUuid).toList();
      debugPrint('💰 Wallet transactions retrieved (Web): ${walletTransactions.length} items for wallet $walletUuid');
      return walletTransactions;
    } catch (e) {
      debugPrint('❌ Error getting transactions by wallet (Web): $e');
      return [];
    }
  }

  static Future<bool> clearTransactions() async {
    try {
      _ensureInitialized();
      final result = await _sharedPrefs!.remove(_transactionKey);
      debugPrint('💰 Transactions cleared (Web): ${result ? 'Success' : 'Failed'}');
      return result;
    } catch (e) {
      debugPrint('❌ Error clearing transactions (Web): $e');
      return false;
    }
  }

  // ==================== GENERAL METHODS ====================

  static Future<bool> clearAll() async {
    try {
      _ensureInitialized();
      final result = await _sharedPrefs!.clear();
      debugPrint('🧹 All data cleared (Web): ${result ? 'Success' : 'Failed'}');
      return result;
    } catch (e) {
      debugPrint('❌ Error clearing all data (Web): $e');
      return false;
    }
  }

  static Set<String> getAllKeys() {
    try {
      _ensureInitialized();
      final keys = _sharedPrefs!.getKeys();
      debugPrint('🔑 All keys (Web): $keys');
      return keys;
    } catch (e) {
      debugPrint('❌ Error getting all keys (Web): $e');
      return <String>{};
    }
  }

  static bool isEmpty() {
    try {
      _ensureInitialized();
      final isEmpty = _sharedPrefs!.getKeys().isEmpty;
      debugPrint('📦 Storage is empty (Web): $isEmpty');
      return isEmpty;
    } catch (e) {
      debugPrint('❌ Error checking if storage is empty (Web): $e');
      return true;
    }
  }

  // ==================== UTILITY METHODS ====================

  static Future<bool> saveData(String key, dynamic data) async {
    try {
      _ensureInitialized();
      
      if (data is String) {
        return await _sharedPrefs!.setString(key, data);
      } else if (data is int) {
        return await _sharedPrefs!.setInt(key, data);
      } else if (data is double) {
        return await _sharedPrefs!.setDouble(key, data);
      } else if (data is bool) {
        return await _sharedPrefs!.setBool(key, data);
      } else if (data is List<String>) {
        return await _sharedPrefs!.setStringList(key, data);
      } else {
        final jsonData = jsonEncode(data);
        final result = await _sharedPrefs!.setString(key, jsonData);
        debugPrint('💾 Generic data saved (Web): ${result ? 'Success' : 'Failed'} for key $key');
        return result;
      }
    } catch (e) {
      debugPrint('❌ Error saving data for key $key (Web): $e');
      return false;
    }
  }

  static T? getData<T>(String key) {
    try {
      _ensureInitialized();
      final value = _sharedPrefs!.get(key);
      
      if (value is T) {
        debugPrint('💾 Generic data retrieved (Web) for key $key: ${value.runtimeType}');
        return value;
      }
      
      debugPrint('💾 No data found for key $key or wrong type (Web)');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting data for key $key (Web): $e');
      return null;
    }
  }

  static Future<bool> deleteData(String key) async {
    try {
      _ensureInitialized();
      final result = await _sharedPrefs!.remove(key);
      debugPrint('💾 Data deleted (Web) for key $key: ${result ? 'Success' : 'Failed'}');
      return result;
    } catch (e) {
      debugPrint('❌ Error deleting data for key $key (Web): $e');
      return false;
    }
  }

  static bool hasKey(String key) {
    try {
      _ensureInitialized();
      final hasKey = _sharedPrefs!.containsKey(key);
      debugPrint('🔑 Key $key exists (Web): $hasKey');
      return hasKey;
    } catch (e) {
      debugPrint('❌ Error checking key $key (Web): $e');
      return false;
    }
  }

  // ==================== PLATFORM INFORMATION ====================

  static String getPlatformInfo() {
    return 'Flutter Web (SharedPreferences -> localStorage)';
  }

  static void printStorageInfo() {
    debugPrint('=====================================');
    debugPrint('🌐 WEB STORAGE SERVICE DEBUG INFO');
    debugPrint('=====================================');
    debugPrint('Platform: ${getPlatformInfo()}');
    debugPrint('Storage initialized: ${_sharedPrefs != null}');
    debugPrint('Has token: ${hasToken()}');
    debugPrint('Has user: ${hasUser()}');
    debugPrint('All keys: ${getAllKeys()}');
    debugPrint('Storage empty: ${isEmpty()}');
    debugPrint('=====================================');
  }
}