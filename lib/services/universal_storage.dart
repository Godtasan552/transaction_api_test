import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UniversalStorageService {
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';
  static const String _transactionKey = 'transactions_data';

  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Ensure preferences is initialized
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== TOKEN MANAGEMENT ====================
  
  // Save token
  static Future<bool> saveToken(String token) async {
    return await prefs.setString(_tokenKey, token);
  }

  // Get token
  static String? getToken() {
    return prefs.getString(_tokenKey);
  }

  // Delete token
  static Future<bool> deleteToken() async {
    return await prefs.remove(_tokenKey);
  }

  // Check if token exists
  static bool hasToken() {
    return prefs.containsKey(_tokenKey);
  }

  // ==================== USER DATA MANAGEMENT ====================

  // Save user data
  static Future<bool> saveUser(Map<String, dynamic> userData) async {
    try {
      final userJson = jsonEncode(userData);
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Get user data
  static Map<String, dynamic>? getUser() {
    try {
      final userJson = prefs.getString(_userKey);
      if (userJson != null && userJson.isNotEmpty) {
        return jsonDecode(userJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Delete user data
  static Future<bool> deleteUser() async {
    return await prefs.remove(_userKey);
  }

  // Check if user data exists
  static bool hasUser() {
    return prefs.containsKey(_userKey) && prefs.getString(_userKey) != null;
  }

  // ==================== TRANSACTION DATA MANAGEMENT ====================

  // Save transactions list
  static Future<bool> saveTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      final transactionsJson = jsonEncode(transactions);
      return await prefs.setString(_transactionKey, transactionsJson);
    } catch (e) {
      print('Error saving transactions: $e');
      return false;
    }
  }

  // Get transactions list
  static List<Map<String, dynamic>> getTransactions() {
    try {
      final transactionsJson = prefs.getString(_transactionKey);
      if (transactionsJson != null && transactionsJson.isNotEmpty) {
        final decoded = jsonDecode(transactionsJson) as List<dynamic>;
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  // Add single transaction
  static Future<bool> addTransaction(Map<String, dynamic> transaction) async {
    try {
      final transactions = getTransactions();
      transactions.add(transaction);
      return await saveTransactions(transactions);
    } catch (e) {
      print('Error adding transaction: $e');
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
        return await saveTransactions(transactions);
      }
      return false;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  // Delete transaction by UUID
  static Future<bool> deleteTransaction(String uuid) async {
    try {
      final transactions = getTransactions();
      transactions.removeWhere((t) => t['uuid'] == uuid);
      return await saveTransactions(transactions);
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  // Get transaction by UUID
  static Map<String, dynamic>? getTransactionByUuid(String uuid) {
    try {
      final transactions = getTransactions();
      for (final transaction in transactions) {
        if (transaction['uuid'] == uuid) {
          return transaction;
        }
      }
      return null;
    } catch (e) {
      print('Error getting transaction by UUID: $e');
      return null;
    }
  }

  // Get transactions by wallet UUID
  static List<Map<String, dynamic>> getTransactionsByWallet(String walletUuid) {
    try {
      final transactions = getTransactions();
      return transactions.where((t) => t['wallet'] == walletUuid).toList();
    } catch (e) {
      print('Error getting transactions by wallet: $e');
      return [];
    }
  }

  // Clear transactions
  static Future<bool> clearTransactions() async {
    return await prefs.remove(_transactionKey);
  }

  // ==================== GENERAL METHODS ====================

  // Clear all stored data
  static Future<bool> clearAll() async {
    try {
      return await prefs.clear();
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }

  // Get all keys (for debugging)
  static Set<String> getAllKeys() {
    return prefs.getKeys();
  }

  // Check if storage is empty
  static bool isEmpty() {
    return prefs.getKeys().isEmpty;
  }

  // ==================== UTILITY METHODS ====================

  // Save generic data with custom key
  static Future<bool> saveData(String key, dynamic data) async {
    try {
      if (data is String) {
        return await prefs.setString(key, data);
      } else if (data is int) {
        return await prefs.setInt(key, data);
      } else if (data is double) {
        return await prefs.setDouble(key, data);
      } else if (data is bool) {
        return await prefs.setBool(key, data);
      } else if (data is List<String>) {
        return await prefs.setStringList(key, data);
      } else {
        // For complex objects, convert to JSON string
        return await prefs.setString(key, jsonEncode(data));
      }
    } catch (e) {
      print('Error saving data for key $key: $e');
      return false;
    }
  }

  // Get generic data with custom key
  static T? getData<T>(String key) {
    try {
      final value = prefs.get(key);
      if (value is T) {
        return value;
      }
      return null;
    } catch (e) {
      print('Error getting data for key $key: $e');
      return null;
    }
  }

  // Delete data by custom key
  static Future<bool> deleteData(String key) async {
    return await prefs.remove(key);
  }

  // Check if custom key exists
  static bool hasKey(String key) {
    return prefs.containsKey(key);
  }
}