import '../controllers/trans_controller.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../utils/api.dart';
import '../utils/navigation_helper.dart';
import '../services/jwt_storage.dart';
import '../services/api_service.dart';

// Transaction Controller สำหรับจัดการข้อมูลธุรกรรม
class TransactionController extends GetxController {
  // Observable variables
  final _transactions = <Transaction>[].obs;
  final _isLoading = false.obs;
  final _selectedTransaction = Rxn<Transaction>();
  final _currentPage = 1.obs; // หน้าเริ่มต้น
  final itemsPerPage = 5;

  int get currentPage => _currentPage.value;

  void nextPage() {
    if ((_currentPage.value * itemsPerPage) < _transactions.length) {
      _currentPage.value++;
    }
  }

  void prevPage() {
    if (_currentPage.value > 1) {
      _currentPage.value--;
    }
  }

  // คืนรายการตามหน้าปัจจุบัน
  List<Transaction> get paginatedTransactions {
    final start = (_currentPage.value - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return _transactions.sublist(
      start,
      end > _transactions.length ? _transactions.length : end,
    );
  }

  // ==================== ยอดสำหรับรายการล่าสุด (paginated) ====================
  double get totalIncomeLatest =>
      paginatedTransactions
          .where((t) => t.type == 1)
          .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenseLatest =>
      paginatedTransactions
          .where((t) => t.type == -1)
          .fold(0.0, (sum, t) => sum + t.amount);

  double get balanceLatest => totalIncomeLatest - totalExpenseLatest;

  // จำนวนหน้าทั้งหมด
  int get totalPages => (_transactions.length / itemsPerPage).ceil();

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
    refreshData();
  }

  // ==================== API METHODS (ใช้ ApiService + JwtStorage) ====================
  // โหลดข้อมูลธุรกรรมจาก API
  Future<void> fetchTransactionsFromAPI({bool showMessage = false}) async {
    try {
      _setLoading(true);
      final token = await JwtStorage.getToken();
      if (token == null) {
        if (showMessage) {
          NavigationHelper.showErrorSnackBar('กรุณาเข้าสู่ระบบก่อน');
        }
        return;
      }
      debugPrint('🔄 Fetching transactions from API...');
      final response = await ApiService().get('/transaction');
      debugPrint('📥 Fetch transactions response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionsData = data['data'] as List<dynamic>;
        final fetchedTransactions = transactionsData
            .map((json) => Transaction.fromApiJson(json))
            .toList();
        _transactions.assignAll(fetchedTransactions);
        debugPrint('✅ Fetched ${fetchedTransactions.length} transactions from API');
        if (showMessage) {
          NavigationHelper.showSuccessSnackBar('โหลดข้อมูลธุรกรรมสำเร็จ');
        }
      } else {
        debugPrint('❌ Failed to fetch transactions: ${response.statusCode} - ${response.reasonPhrase}');
        debugPrint('Response body: ${response.body}');
        if (showMessage) {
          NavigationHelper.showErrorSnackBar('ไม่สามารถโหลดข้อมูลได้ (${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching transactions: $e');
      if (showMessage) {
        NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
    }
  }

  // ส่งข้อมูลธุรกรรมไป API
  Future<bool> syncTransactionToAPI(Transaction transaction) async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) {
        debugPrint('❌ No token found for sync');
        return false;
      }
      debugPrint('🔄 Syncing transaction to API...');
      final response = await ApiService().post('/transaction', transaction.toApiJson());
      debugPrint('📥 Sync transaction response: ${response.statusCode}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Transaction synced successfully to API');
        return true;
      } else {
        debugPrint('❌ Failed to sync transaction: ${response.statusCode} - ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error syncing transaction: $e');
      return false;
    }
  }

  // ==================== LOCAL STORAGE METHODS ====================
  // (ลบฟังก์ชัน local storage ถ้าไม่ต้องการ offline)

  // ==================== TRANSACTION CRUD ====================
  // เพิ่มธุรกรรมใหม่ (sync API ก่อน แล้วค่อยเพิ่มใน list)
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
        wallet: walletId ?? 'default',
        name: name,
        desc: description,
        amount: amount,
        type: type,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      // ส่งไป API ก่อน
      final synced = await syncTransactionToAPI(transaction);
      if (synced) {
        _transactions.add(transaction);
        update();
        final typeText = type == 1 ? 'รายรับ' : 'รายจ่าย';
        NavigationHelper.showSuccessSnackBar('เพิ่ม$typeTextสำเร็จ');
        return true;
      } else {
        NavigationHelper.showErrorSnackBar('เพิ่มธุรกรรมไม่สำเร็จ');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error adding transaction: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการเพิ่มธุรกรรม');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // อัปเดตธุรกรรม (ควรเรียก API PUT /transaction/[id])
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
      // เรียก API PUT
      final response = await ApiService().put('/transaction/$uuid', updatedTransaction.toApiJson());
      if (response.statusCode == 200) {
        _transactions[index] = updatedTransaction;
        update();
        NavigationHelper.showSuccessSnackBar('แก้ไขธุรกรรมสำเร็จ');
        debugPrint('✅ Updated transaction: ${updatedTransaction.name}');
        return true;
      } else {
        debugPrint('❌ Failed to update transaction: ${response.statusCode}');
        NavigationHelper.showErrorSnackBar('แก้ไขธุรกรรมไม่สำเร็จ');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating transaction: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการแก้ไข');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ลบธุรกรรม (API DELETE /transaction/[id])
  Future<bool> deleteTransaction(String uuid) async {
    try {
      _setLoading(true);
      final transaction = _transactions.firstWhereOrNull((t) => t.uuid == uuid);
      if (transaction == null) {
        NavigationHelper.showErrorSnackBar('ไม่พบธุรกรรมที่ต้องการลบ');
        return false;
      }
      final response = await ApiService().delete('/transaction/$uuid');
      if (response.statusCode == 200) {
        _transactions.removeWhere((t) => t.uuid == uuid);
        update();
        NavigationHelper.showSuccessSnackBar('ลบธุรกรรมสำเร็จ');
        debugPrint('✅ Deleted transaction: ${transaction.name}');
        return true;
      } else {
        debugPrint('❌ Failed to delete transaction: ${response.statusCode}');
        NavigationHelper.showErrorSnackBar('ลบธุรกรรมไม่สำเร็จ');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting transaction: $e');
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
        .where(
          (transaction) =>
              transaction.name.toLowerCase().contains(query.toLowerCase()) ||
              (transaction.desc?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
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
      filtered = filtered
          .where(
            (t) => t.date.isAfter(startDate.subtract(const Duration(days: 1))),
          )
          .toList();
    }
    if (endDate != null) {
      filtered = filtered
          .where((t) => t.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }
    return filtered;
  }

  // กรองธุรกรรมตามเดือน
  List<Transaction> filterByMonth(int year, int month) {
    return _transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
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
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // สถิติตามหมวดหมู่ (ใช้ name เป็นหมวดหมู่)
  Map<String, double> getCategoryStatistics({int? type}) {
    final filteredTransactions = type != null
        ? _transactions.where((t) => t.type == type).toList()
        : _transactions;
    final Map<String, double> categoryTotals = {};
    for (final transaction in filteredTransactions) {
      final category = transaction.name; // หรือสามารถใช้ field อื่นเป็นหมวดหมู่
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + transaction.amount;
    }
    return categoryTotals;
  }

  // ==================== UTILITY METHODS ====================
  // เลือกธุรกรรม
  void selectTransaction(Transaction? transaction) {
    _selectedTransaction.value = transaction;
  }

  // ล้างข้อมูลธุรกรรมทั้งหมด (เฉพาะในแอป)
  Future<void> clearAllTransactions() async {
    try {
      _setLoading(true);
      _transactions.clear();
      NavigationHelper.showSuccessSnackBar('ล้างข้อมูลธุรกรรมทั้งหมดแล้ว');
      debugPrint('✅ Cleared all transactions');
    } catch (e) {
      debugPrint('❌ Error clearing transactions: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการล้างข้อมูล');
    } finally {
      _setLoading(false);
    }
  }

  // รีเฟรชข้อมูล (โหลดจาก API)
  Future<void> refreshData() async {
    try {
      _setLoading(true);
      await fetchTransactionsFromAPI(showMessage: false);
      debugPrint('✅ Data refreshed successfully (from API)');
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
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
        _transactions.sort(
          (a, b) =>
              ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
        );
        break;
      case TransactionSortBy.amount:
        _transactions.sort(
          (a, b) => ascending
              ? a.amount.compareTo(b.amount)
              : b.amount.compareTo(a.amount),
        );
        break;
      case TransactionSortBy.name:
        _transactions.sort(
          (a, b) =>
              ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name),
        );
        break;
      case TransactionSortBy.type:
        _transactions.sort(
          (a, b) =>
              ascending ? a.type.compareTo(b.type) : b.type.compareTo(a.type),
        );
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

// Transaction Model (ไม่เปลี่ยนแปลง)
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
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
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
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
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
enum TransactionSortBy { date, amount, name, type }

// Binding สำหรับ Dependency Injection
class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionController>(() => TransactionController());
  }
}