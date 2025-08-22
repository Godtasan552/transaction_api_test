import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../utils/api.dart';
import '../utils/navigation_helper.dart';
import '../services/universal_storage.dart';

// Transaction Controller สำหรับจัดการข้อมูลธุรกรรม
class TransactionController extends GetxController {
  // Observable variables
  final _transactions = <Transaction>[].obs;
  final _isLoading = false.obs;
  final _selectedTransaction = Rxn<Transaction>();

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading.value;
  Transaction? get selectedTransaction => _selectedTransaction.value;

  // Filtered transactions
  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.type == 1).toList();

  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.type == -1).toList();

  // Summary calculations
  double get totalIncome =>
      incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense =>
      expenseTransactions.fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  @override
  void onInit() {
    super.onInit();
    _initStorage();
  }

  Future<void> _initStorage() async {
    await UniversalStorageService.init();
    await loadTransactions();
  }

  // ==================== API METHODS ====================

  // โหลดข้อมูลธุรกรรมจาก API
  Future<void> fetchTransactionsFromAPI() async {
    try {
      _setLoading(true);

      final token = UniversalStorageService.getToken();
      if (token == null) {
        NavigationHelper.showErrorSnackBar('กรุณาเข้าสู่ระบบก่อน');
        return;
      }

      final serviceUrl = '$BASE_URL$SHOW_TRANSACTION_ENDPOINT';
      final response = await http.get(
        Uri.parse(serviceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Fetch transactions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionsData = data['data'] as List<dynamic>;

        final fetchedTransactions = transactionsData
            .map((json) => Transaction.fromApiJson(json))
            .toList();

        _transactions.assignAll(fetchedTransactions);

        // บันทึกลง local storage
        await _saveTransactionsToLocal();

        debugPrint('Fetched ${fetchedTransactions.length} transactions from API');
        NavigationHelper.showSuccessSnackBar('โหลดข้อมูลธุรกรรมสำเร็จ');
      } else {
        debugPrint('Failed to fetch transactions: ${response.reasonPhrase}');
        NavigationHelper.showErrorSnackBar('ไม่สามารถโหลดข้อมูลได้');
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ส่งข้อมูลธุรกรรมไป API
  Future<bool> syncTransactionToAPI(Transaction transaction) async {
    try {
      final token = UniversalStorageService.getToken();
      if (token == null) {
        debugPrint('No token found for sync');
        return false;
      }

      final serviceUrl = '$BASE_URL$SHOW_TRANSACTION_ENDPOINT';
      final response = await http.post(
        Uri.parse(serviceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(transaction.toApiJson()),
      );

      debugPrint('Sync transaction response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Transaction synced successfully to API');
        return true;
      } else {
        debugPrint('Failed to sync transaction: ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing transaction: $e');
      return false;
    }
  }

  // ==================== LOCAL STORAGE METHODS ====================

  // โหลดข้อมูลธุรกรรมจาก local storage
  Future<void> loadTransactions() async {
    try {
      final transactionsData = UniversalStorageService.getTransactions();
      final loadedTransactions = transactionsData
          .map((json) => Transaction.fromJson(json))
          .toList();

      _transactions.assignAll(loadedTransactions);
      debugPrint('Loaded ${loadedTransactions.length} transactions from local storage');
    } catch (e) {
      debugPrint('Error loading transactions from local: $e');
    }
  }

  // บันทึกข้อมูลธุรกรรมลง local storage
  Future<void> _saveTransactionsToLocal() async {
    try {
      final transactionsJson = _transactions
          .map((transaction) => transaction.toJson())
          .toList();

      await UniversalStorageService.saveTransactions(transactionsJson);
      debugPrint('Saved ${_transactions.length} transactions to local storage');
    } catch (e) {
      debugPrint('Error saving transactions to local: $e');
    }
  }

  // ==================== TRANSACTION CRUD ====================

  // เพิ่มธุรกรรมใหม่
  Future<bool> addTransaction({
    required String name,
    required double amount,
    required int type, // -1 = expense, 1 = income
    String? description,
    DateTime? date,
    String? walletId,
  }) async {
    try {
      _setLoading(true);

      final transaction = Transaction(
        uuid: const Uuid().v4(),
        wallet: walletId ?? 'default', // ใช้ default wallet หากไม่ระบุ
        name: name,
        desc: description,
        amount: amount,
        type: type,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // เพิ่มลงใน local list
      _transactions.add(transaction);

      // บันทึกลง local storage
      await _saveTransactionsToLocal();

      // พยายาม sync กับ API
      final synced = await syncTransactionToAPI(transaction);
      if (!synced) {
        debugPrint('Failed to sync new transaction to API, saved locally only');
      }

      final typeText = type == 1 ? 'รายรับ' : 'รายจ่าย';
      NavigationHelper.showSuccessSnackBar('เพิ่ม$typeTextสำเร็จ');

      debugPrint('Added transaction: ${transaction.name} (${transaction.amount})');
      return true;
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการเพิ่มธุรกรรม');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // อัปเดตธุรกรรม
  Future<bool> updateTransaction({
    required String uuid,
    String? name,
    double? amount,
    int? type,
    String? description,
    DateTime? date,
    String? walletId,
  }) async {
    try {
      _setLoading(true);

      final index = _transactions.indexWhere((t) => t.uuid == uuid);
      if (index == -1) {
        NavigationHelper.showErrorSnackBar('ไม่พบธุรกรรมที่ต้องการแก้ไข');
        return false;
      }

      final existingTransaction = _transactions[index];
      final updatedTransaction = existingTransaction.copyWith(
        name: name,
        amount: amount,
        type: type,
        desc: description,
        date: date,
        wallet: walletId,
        updatedAt: DateTime.now(),
      );

      // อัปเดตใน local list
      _transactions[index] = updatedTransaction;

      // บันทึกลง local storage
      await _saveTransactionsToLocal();

      // พยายาม sync กับ API
      final synced = await syncTransactionToAPI(updatedTransaction);
      if (!synced) {
        debugPrint('Failed to sync updated transaction to API, saved locally only');
      }

      NavigationHelper.showSuccessSnackBar('แก้ไขธุรกรรมสำเร็จ');
      debugPrint('Updated transaction: ${updatedTransaction.name}');
      return true;
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการแก้ไข');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ลบธุรกรรม
  Future<bool> deleteTransaction(String uuid) async {
    try {
      _setLoading(true);

      final transaction = _transactions.firstWhereOrNull((t) => t.uuid == uuid);
      if (transaction == null) {
        NavigationHelper.showErrorSnackBar('ไม่พบธุรกรรมที่ต้องการลบ');
        return false;
      }

      // ลบจาก local list
      _transactions.removeWhere((t) => t.uuid == uuid);

      // บันทึกลง local storage
      await _saveTransactionsToLocal();

      // TODO: เรียก API เพื่อลบจากเซิร์ฟเวอร์
      // await _deleteTransactionFromAPI(uuid);

      NavigationHelper.showSuccessSnackBar('ลบธุรกรรมสำเร็จ');
      debugPrint('Deleted transaction: ${transaction.name}');
      return true;
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการลบ');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== SEARCH & FILTER ====================

  // ค้นหาธุรกรรมตามชื่อ
  List<Transaction> searchTransactions(String query) {
    if (query.isEmpty) return _transactions;

    return _transactions
        .where((transaction) =>
            transaction.name.toLowerCase().contains(query.toLowerCase()) ||
            (transaction.desc?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }

  // กรองธุรกรรมตามประเภท
  List<Transaction> filterByType(int? type) {
    if (type == null) return _transactions;
    return _transactions.where((t) => t.type == type).toList();
  }

  // กรองธุรกรรมตามช่วงวันที่
  List<Transaction> filterByDateRange(DateTime? startDate, DateTime? endDate) {
    List<Transaction> filtered = _transactions;

    if (startDate != null) {
      filtered = filtered.where((t) => 
          t.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
    }

    if (endDate != null) {
      filtered = filtered.where((t) => 
          t.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    }

    return filtered;
  }

  // กรองธุรกรรมตามเดือน
  List<Transaction> filterByMonth(int year, int month) {
    return _transactions.where((t) => 
        t.date.year == year && t.date.month == month).toList();
  }

  // ==================== STATISTICS ====================

  // สถิติรายเดือน
  Map<String, double> getMonthlyStatistics(int year, int month) {
    final monthlyTransactions = filterByMonth(year, month);
    final income = monthlyTransactions
        .where((t) => t.type == 1)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = monthlyTransactions
        .where((t) => t.type == -1)
        .fold(0.0, (sum, t) => sum + t.amount);

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  // สถิติตามหมวดหมู่ (ใช้ name เป็นหมวดหมู่)
  Map<String, double> getCategoryStatistics({int? type}) {
    final filteredTransactions = type != null 
        ? _transactions.where((t) => t.type == type).toList()
        : _transactions;

    final Map<String, double> categoryTotals = {};

    for (final transaction in filteredTransactions) {
      final category = transaction.name; // หรือสามารถใช้ field อื่นเป็นหมวดหมู่
      categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }

  // ==================== UTILITY METHODS ====================

  // เลือกธุรกรรม
  void selectTransaction(Transaction? transaction) {
    _selectedTransaction.value = transaction;
  }

  // ล้างข้อมูลธุรกรรมทั้งหมด
  Future<void> clearAllTransactions() async {
    try {
      _setLoading(true);

      _transactions.clear();
      await UniversalStorageService.clearTransactions();

      NavigationHelper.showSuccessSnackBar('ล้างข้อมูลธุรกรรมทั้งหมดแล้ว');
      debugPrint('Cleared all transactions');
    } catch (e) {
      debugPrint('Error clearing transactions: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการล้างข้อมูล');
    } finally {
      _setLoading(false);
    }
  }

  // รีเฟรชข้อมูล (ดึงจาก API และ local storage)
  Future<void> refreshData() async {
    try {
      _setLoading(true);
      
      // โหลดจาก local storage ก่อน
      await loadTransactions();
      
      // จากนั้นพยายามดึงจาก API
      await fetchTransactionsFromAPI();
      
      debugPrint('Data refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการรีเฟรชข้อมูล');
    } finally {
      _setLoading(false);
    }
  }

  // เรียงลำดับธุรกรรม
  void sortTransactions({
    TransactionSortBy sortBy = TransactionSortBy.date,
    bool ascending = false,
  }) {
    switch (sortBy) {
      case TransactionSortBy.date:
        _transactions.sort((a, b) => ascending 
            ? a.date.compareTo(b.date) 
            : b.date.compareTo(a.date));
        break;
      case TransactionSortBy.amount:
        _transactions.sort((a, b) => ascending 
            ? a.amount.compareTo(b.amount) 
            : b.amount.compareTo(a.amount));
        break;
      case TransactionSortBy.name:
        _transactions.sort((a, b) => ascending 
            ? a.name.compareTo(b.name) 
            : b.name.compareTo(a.name));
        break;
      case TransactionSortBy.type:
        _transactions.sort((a, b) => ascending 
            ? a.type.compareTo(b.type) 
            : b.type.compareTo(a.type));
        break;
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading.value = value;
  }

  // Debug methods
  void printTransactionInfo() {
    debugPrint('=== Transaction Info ===');
    debugPrint('Total Transactions: ${_transactions.length}');
    debugPrint('Income Transactions: ${incomeTransactions.length}');
    debugPrint('Expense Transactions: ${expenseTransactions.length}');
    debugPrint('Total Income: $totalIncome');
    debugPrint('Total Expense: $totalExpense');
    debugPrint('Balance: $balance');
    debugPrint('========================');
  }
}

// Transaction Model
class Transaction {
  final String uuid;
  final String wallet;
  final String name;
  final String? desc;
  final double amount;
  final int type; // -1 = expense, 1 = income
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.uuid,
    required this.wallet,
    required this.name,
    this.desc,
    required this.amount,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to/from JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'wallet': wallet,
      'name': name,
      'desc': desc,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      uuid: json['uuid'] ?? '',
      wallet: json['wallet'] ?? '',
      name: json['name'] ?? '',
      desc: json['desc'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 1,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert to/from JSON for API
  Map<String, dynamic> toApiJson() {
    return {
      'uuid': uuid,
      'wallet': wallet,
      'name': name,
      'desc': desc,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromApiJson(Map<String, dynamic> json) {
    return Transaction(
      uuid: json['uuid'] ?? '',
      wallet: json['wallet'] ?? '',
      name: json['name'] ?? '',
      desc: json['desc'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 1,
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Create copy with updated fields
  Transaction copyWith({
    String? uuid,
    String? wallet,
    String? name,
    String? desc,
    double? amount,
    int? type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      uuid: uuid ?? this.uuid,
      wallet: wallet ?? this.wallet,
      name: name ?? this.name,
      desc: desc ?? this.desc,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  String get typeText => type == 1 ? 'รายรับ' : 'รายจ่าย';
  String get formattedAmount => '${amount.toStringAsFixed(2)} ฿';
  String get formattedDate => '${date.day}/${date.month}/${date.year}';
  
  @override
  String toString() {
    return 'Transaction{uuid: $uuid, name: $name, amount: $amount, type: $type}';
  }
}

// Enum สำหรับการเรียงลำดับ
enum TransactionSortBy {
  date,
  amount,
  name,
  type,
}

// Binding สำหรับ Dependency Injection
class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionController>(() => TransactionController());
  }
}