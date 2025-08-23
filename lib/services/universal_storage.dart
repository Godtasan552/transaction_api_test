import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

class UniversalStorageService {
  static const String _boxName = 'auth_box';
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _transactionKey = 'transactions_data';

  // For Mobile (Hive)
  static Box? _hiveBox;
  
  // For Web (SharedPreferences)
  static SharedPreferences? _sharedPrefs;

  // Platform detection
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;

  // Initialize storage based on platform
  static Future<void> init() async {
    try {
      if (isWeb) {
        // Initialize SharedPreferences for Web
        _sharedPrefs = await SharedPreferences.getInstance();
        debugPrint('✅ StorageService initialized for Web (SharedPreferences)');
      } else {
        // Initialize Hive for Mobile
        _hiveBox = await Hive.openBox(_boxName);
        debugPrint('✅ StorageService initialized for Mobile (Hive)');
      }
    } catch (e) {
      debugPrint('❌ Error initializing StorageService: $e');
      rethrow;
    }
  }

  // Ensure storage is initialized
  static void _ensureInitialized() {
    if (isWeb && _sharedPrefs == null) {
      throw Exception('SharedPreferences not initialized. Call init() first.');
    }
    if (isMobile && _hiveBox == null) {
      throw Exception('Hive box not initialized. Call init() first.');
    }
  }

  // ==================== TOKEN MANAGEMENT ====================
  
    // Save token
  static Future<bool> saveToken(String token) async {
    _ensureInitialized();
    if (isWeb) {
      return await _sharedPrefs!.setString(_tokenKey, token);
    } else {
      await _hiveBox!.put(_tokenKey, token);
      return true;
    }
  }
  
  // Get token
  static String? getToken() {
    _ensureInitialized();
    if (isWeb) {
      return _sharedPrefs!.getString(_tokenKey);
    } else {
      return _hiveBox!.get(_tokenKey);
    }
  }

  // Delete token
  static Future<bool> deleteToken() async {
    try {
      _ensureInitialized();
      
      if (isWeb) {
        final result = await _sharedPrefs!.remove(_tokenKey);
        debugPrint('🔐 Token deleted (Web): ${result ? 'Success' : 'Failed'}');
        return result;
      } else {
        await _hiveBox!.delete(_tokenKey);
        debugPrint('🔐 Token deleted (Mobile): Success');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error deleting token: $e');
      return false;
    }
  }

  // Check if token exists
  static bool hasToken() {
    try {
      _ensureInitialized();
      
      bool hasToken;
      String? token;
      
      if (isWeb) {
        hasToken = _sharedPrefs!.containsKey(_tokenKey);
        token = _sharedPrefs!.getString(_tokenKey);
      } else {
        hasToken = _hiveBox!.containsKey(_tokenKey);
        token = _hiveBox!.get(_tokenKey);
      }
      
      final isValid = hasToken && token != null && token.isNotEmpty;
      debugPrint('🔐 Has valid token (${isWeb ? 'Web' : 'Mobile'}): $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking token: $e');
      return false;
    }
  }

  // ==================== USER DATA MANAGEMENT ====================

  // Save user data
  static Future<bool> saveUser(Map<String, dynamic> userData) async {
    try {
      _ensureInitialized();
      
      if (isWeb) {
        final userJson = jsonEncode(userData);
        final result = await _sharedPrefs!.setString(_userKey, userJson);
        debugPrint('👤 User data saved (Web): ${result ? 'Success' : 'Failed'}');
        return result;
      } else {
        final userJson = jsonEncode(userData);
        await _hiveBox!.put(_userKey, userJson);
        debugPrint('👤 User data saved (Mobile): Success');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error saving user data: $e');
      return false;
    }
  }

  // Get user data
  static Map<String, dynamic>? getUser() {
    try {
      _ensureInitialized();
      
      String? userJson;
      if (isWeb) {
        userJson = _sharedPrefs!.getString(_userKey);
      } else {
        userJson = _hiveBox!.get(_userKey);
      }
      
      if (userJson != null && userJson.isNotEmpty) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        debugPrint('👤 User data retrieved (${isWeb ? 'Web' : 'Mobile'}): ${userData['firstName']} ${userData['lastName']}');
        return userData;
      }
      
      debugPrint('👤 No user data found (${isWeb ? 'Web' : 'Mobile'})');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      return null;
    }
  }

  // Delete user data
  static Future<bool> deleteUser() async {
    try {
      _ensureInitialized();
      
      if (isWeb) {
        final result = await _sharedPrefs!.remove(_userKey);
        debugPrint('👤 User data deleted (Web): ${result ? 'Success' : 'Failed'}');
        return result;
      } else {
        await _hiveBox!.delete(_userKey);
        debugPrint('👤 User data deleted (Mobile): Success');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      return false;
    }
  }

  // Check if user data exists
  static bool hasUser() {
    try {
      _ensureInitialized();
      
      bool hasUser;
      String? userJson;
      
      if (isWeb) {
        hasUser = _sharedPrefs!.containsKey(_userKey);
        userJson = _sharedPrefs!.getString(_userKey);
      } else {
        hasUser = _hiveBox!.containsKey(_userKey);
        userJson = _hiveBox!.get(_userKey);
      }
      
      final isValid = hasUser && userJson != null && userJson.isNotEmpty;
      debugPrint('👤 Has valid user data (${isWeb ? 'Web' : 'Mobile'}): $isValid');
      return isValid;
    } catch (e) {
      debugPrint('❌ Error checking user data: $e');
      return false;
    }
  }

  // ==================== TRANSACTION DATA MANAGEMENT ====================

  // Save transactions list
  static Future<bool> saveTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      _ensureInitialized();
      
      final transactionsJson = jsonEncode(transactions);
      
      if (isWeb) {
        final result = await _sharedPrefs!.setString(_transactionKey, transactionsJson);
        debugPrint('💰 Transactions saved (Web): ${result ? 'Success' : 'Failed'} (${transactions.length} items)');
        return result;
      } else {
        await _hiveBox!.put(_transactionKey, transactionsJson);
        debugPrint('💰 Transactions saved (Mobile): Success (${transactions.length} items)');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error saving transactions: $e');
      return false;
    }
  }

  // Get transactions list
  static List<Map<String, dynamic>> getTransactions() {
    try {
      _ensureInitialized();
      
      String? transactionsJson;
      if (isWeb) {
        transactionsJson = _sharedPrefs!.getString(_transactionKey);
      } else {
        transactionsJson = _hiveBox!.get(_transactionKey);
      }
      
      if (transactionsJson != null && transactionsJson.isNotEmpty) {
        final decoded = jsonDecode(transactionsJson) as List<dynamic>;
        final transactions = decoded.cast<Map<String, dynamic>>();
        debugPrint('💰 Transactions retrieved (${isWeb ? 'Web' : 'Mobile'}): ${transactions.length} items');
        return transactions;
      }
      
      debugPrint('💰 No transactions found (${isWeb ? 'Web' : 'Mobile'})');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting transactions: $e');
      return [];
    }
  }

  // Add single transaction
  static Future<bool> addTransaction(Map<String, dynamic> transaction) async {
    try {
      final transactions = getTransactions();
      transactions.add(transaction);
      final result = await saveTransactions(transactions);
      debugPrint('💰 Transaction added (${isWeb ? 'Web' : 'Mobile'}): ${result ? 'Success' : 'Failed'} - ${transaction['name']}');
      return result;
    } catch (e) {
      debugPrint('❌ Error adding transaction: $e');
      return false;
    }
  }

  // Update transaction by UUID
  static Future<bool> updateTransaction(String uuid, Map<String, dynamic> updatedTransaction) async {
    try {
      final transactions = getTransactions();
      final index = transactions.indexWhere((t) => t['uuid'] == uuid);
      
      if (index != -1) {
        transactions[index] = updatedTransaction;
        final result = await saveTransactions(transactions);
        debugPrint('💰 Transaction updated (${isWeb ? 'Web' : 'Mobile'}): ${result ? 'Success' : 'Failed'} - ${updatedTransaction['name']}');
        return result;
      }
      
      debugPrint('💰 Transaction not found for update: $uuid');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating transaction: $e');
      return false;
    }
  }

  // Delete transaction by UUID
  static Future<bool> deleteTransaction(String uuid) async {
    try {
      final transactions = getTransactions();
      final initialCount = transactions.length;
      transactions.removeWhere((t) => t['uuid'] == uuid);
      
      if (transactions.length < initialCount) {
        final result = await saveTransactions(transactions);
        debugPrint('💰 Transaction deleted (${isWeb ? 'Web' : 'Mobile'}): ${result ? 'Success' : 'Failed'} - $uuid');
        return result;
      }
      
      debugPrint('💰 Transaction not found for deletion: $uuid');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting transaction: $e');
      return false;
    }
  }

  // Get transaction by UUID
  static Map<String, dynamic>? getTransactionByUuid(String uuid) {
    try {
      final transactions = getTransactions();
      for (final transaction in transactions) {
        if (transaction['uuid'] == uuid) {
          debugPrint('💰 Transaction found by UUID (${isWeb ? 'Web' : 'Mobile'}): ${transaction['name']}');
          return transaction;
        }
      }
      debugPrint('💰 Transaction not found by UUID: $uuid');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting transaction by UUID: $e');
      return null;
    }
  }

  // Get transactions by wallet UUID
  static List<Map<String, dynamic>> getTransactionsByWallet(String walletUuid) {
    try {
      final transactions = getTransactions();
      final walletTransactions = transactions.where((t) => t['wallet'] == walletUuid).toList();
      debugPrint('💰 Wallet transactions retrieved (${isWeb ? 'Web' : 'Mobile'}): ${walletTransactions.length} items for wallet $walletUuid');
      return walletTransactions;
    } catch (e) {
      debugPrint('❌ Error getting transactions by wallet: $e');
      return [];
    }
  }

  // Clear transactions
  static Future<bool> clearTransactions() async {
    try {
      _ensureInitialized();
      
      if (isWeb) {
        final result = await _sharedPrefs!.remove(_transactionKey);
        debugPrint('💰 Transactions cleared (Web): ${result ? 'Success' : 'Failed'}');
        return result;
      } else {
        await _hiveBox!.delete(_transactionKey);
        debugPrint('💰 Transactions cleared (Mobile): Success');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error clearing transactions: $e');
      return false;
    }
  }

  // ==================== GENERAL METHODS ====================

  // Clear all stored data
  static Future<bool> clearAll() async {
    try {
      _ensureInitialized();
      
      if (isWeb) {
        final result = await _sharedPrefs!.clear();
        debugPrint('🧹 All data cleared (Web): ${result ? 'Success' : 'Failed'}');
        return result;
      } else {
        await _hiveBox!.clear();
        debugPrint('🧹 All data cleared (Mobile): Success');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error clearing all data: $e');
      return false;
    }
  }

  // Get all keys (for debugging)
  static Set<String> getAllKeys() {
    try {
      _ensureInitialized();
      
      Set<String> keys;
      if (isWeb) {
        keys = _sharedPrefs!.getKeys();
      } else {
        keys = _hiveBox!.keys.cast<String>().toSet();
      }
      
      debugPrint('🔑 All keys (${isWeb ? 'Web' : 'Mobile'}): $keys');
      return keys;
    } catch (e) {
      debugPrint('❌ Error getting all keys: $e');
      return <String>{};
    }
  }

  // Check if storage is empty
  static bool isEmpty() {
    try {
      _ensureInitialized();
      
      bool isEmpty;
      if (isWeb) {
        isEmpty = _sharedPrefs!.getKeys().isEmpty;
      } else {
        isEmpty = _hiveBox!.keys.isEmpty;
      }
      
      debugPrint('📦 Storage is empty (${isWeb ? 'Web' : 'Mobile'}): $isEmpty');
      return isEmpty;
    } catch (e) {
      debugPrint('❌ Error checking if storage is empty: $e');
      return true;
    }
  }

  // ==================== UTILITY METHODS ====================

  // Save generic data with custom key
  static Future<bool> saveData(String key, dynamic data) async {
    try {
      _ensureInitialized();
      
      if (isWeb) {
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
      } else {
        await _hiveBox!.put(key, data);
        debugPrint('💾 Generic data saved (Mobile): Success for key $key');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error saving data for key $key: $e');
      return false;
    }
  }

  // Get generic data with custom key
  static T? getData<T>(String key) {
    try {
      _ensureInitialized();
      
      dynamic value;
      if (isWeb) {
        value = _sharedPrefs!.get(key);
      } else {
        value = _hiveBox!.get(key);
      }
      
      if (value is T) {
        debugPrint('💾 Generic data retrieved (${isWeb ? 'Web' : 'Mobile'}) for key $key: ${value.runtimeType}');
        return value;
      }
      
      debugPrint('💾 No data found for key $key or wrong type (${isWeb ? 'Web' : 'Mobile'})');
      return null;
    } catch (e) {
      debugPrint('❌ Error getting data for key $key: $e');
      return null;
    }
  }

  // Delete data by custom key
  static Future<bool> deleteData(String key) async {
    try {
      _ensureInitialized();
      
      if (isWeb) {
        final result = await _sharedPrefs!.remove(key);
        debugPrint('💾 Data deleted (Web) for key $key: ${result ? 'Success' : 'Failed'}');
        return result;
      } else {
        await _hiveBox!.delete(key);
        debugPrint('💾 Data deleted (Mobile) for key $key: Success');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error deleting data for key $key: $e');
      return false;
    }
  }

  // Check if custom key exists
  static bool hasKey(String key) {
    try {
      _ensureInitialized();
      
      bool hasKey;
      if (isWeb) {
        hasKey = _sharedPrefs!.containsKey(key);
      } else {
        hasKey = _hiveBox!.containsKey(key);
      }
      
      debugPrint('🔑 Key $key exists (${isWeb ? 'Web' : 'Mobile'}): $hasKey');
      return hasKey;
    } catch (e) {
      debugPrint('❌ Error checking key $key: $e');
      return false;
    }
  }

  // ==================== PLATFORM INFORMATION ====================

  // Get platform info for debugging
  static String getPlatformInfo() {
    if (kIsWeb) {
      return 'Flutter Web (SharedPreferences)';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
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
    return 'Unknown Platform';
  }

  // Debug method to print storage info
  static void printStorageInfo() {
    debugPrint('=====================================');
    debugPrint('📱 HYBRID STORAGE SERVICE DEBUG INFO');
    debugPrint('=====================================');
    debugPrint('Platform: ${getPlatformInfo()}');
    debugPrint('Is Web: $isWeb');
    debugPrint('Is Mobile: $isMobile');
    debugPrint('Storage initialized: ${isWeb ? _sharedPrefs != null : _hiveBox != null}');
    debugPrint('Has token: ${hasToken()}');
    debugPrint('Has user: ${hasUser()}');
    debugPrint('All keys: ${getAllKeys()}');
    debugPrint('Storage empty: ${isEmpty()}');
    debugPrint('=====================================');
  }
}