import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:form_validate/components/drawer.dart';
import 'package:form_validate/services/storage_service.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../services/universal_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController authController = Get.find<AuthController>();
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = false;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;
  double totalIncome = 0;
  double totalExpense = 0;
  double totalBalance = 0; // เพิ่มยอดคงเหลือ

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await UniversalStorageService.init();
      final token = UniversalStorageService.getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          errorMessage = "กรุณาเข้าสู่ระบบใหม่";
          isLoading = false;
        });
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      final url = Uri.parse(
        "https://transactions-cs.vercel.app/api/transaction?page=$currentPage&limit=5",
      );

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - กรุณาลองใหม่อีกครั้ง');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          transactions = List<Map<String, dynamic>>.from(data['data'] ?? []);
          totalPages = data['totalPages'] ?? 1;
          _calculateTotals();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = "กรุณาเข้าสู่ระบบใหม่";
          isLoading = false;
        });
        Get.offAllNamed(AppRoutes.login);
      } else {
        setState(() {
          errorMessage = "เกิดข้อผิดพลาดในการโหลดข้อมูล";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "เกิดข้อผิดพลาด: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  void _calculateTotals() {
    totalIncome = 0;
    totalExpense = 0;
    
    for (var transaction in transactions) {
      final amount = (transaction['amount'] ?? 0).toDouble();
      final type = transaction['type'] ?? 0;
      
      if (type == 1) {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }
    }
    
    // คำนวณยอดคงเหลือ
    totalBalance = totalIncome - totalExpense;
  }

  Future<void> _navigateToCreateTransaction() async {
    final result = await Get.toNamed(AppRoutes.createTransaction);
    
    // ถ้าสร้างธุรกรรมสำเร็จ รีเฟรชข้อมูล
    if (result == true) {
      _loadTransactions();
    }
  }

  void _changePage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
      _loadTransactions();
    }
  }


  /*
   เปลี่ยนจาก popup เป็นไปหน้า detail
  void _navigateToTransactionDetail(Map<String, dynamic> transaction) {
    ไปหน้า detail แทนการแสดง dialog
    Get.toNamed(
      AppRoutes.transactionDetail, // จะต้องเพิ่ม route นี้ใน app_routes.dart
      arguments: transaction,
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: Obx(() {
          final user = authController.currentUser;
          
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Summary Cards - เพิ่มยอดคงเหลือ
                  // Balance Card (แสดงใหญ่)
                  Card(
                    color: totalBalance >= 0 ? Colors.blue[50] : Colors.orange[50],
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet, 
                            color: totalBalance >= 0 ? Colors.blue : Colors.orange, 
                            size: 32
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'ยอดคงเหลือ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '฿${totalBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: totalBalance >= 0 ? Colors.blue : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Income and Expense Cards
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.arrow_upward, 
                                     color: Colors.green, size: 24),
                                const SizedBox(height: 8),
                                const Text('รายรับ', 
                                     style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('฿${totalIncome.toStringAsFixed(2)}',
                                     style: const TextStyle(
                                       fontSize: 16, 
                                       color: Colors.green,
                                       fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Card(
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.arrow_downward, 
                                     color: Colors.red, size: 24),
                                const SizedBox(height: 8),
                                const Text('รายจ่าย', 
                                     style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('฿${totalExpense.toStringAsFixed(2)}',
                                     style: const TextStyle(
                                       fontSize: 16, 
                                       color: Colors.red,
                                       fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToCreateTransaction,
                          icon: const Icon(Icons.add),
                          label: const Text('เพิ่มรายการ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'รายการธุรกรรมล่าสุด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (totalPages > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'หน้า $currentPage/$totalPages',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (errorMessage != null)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _loadTransactions,
                              child: const Text('ลองใหม่'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (transactions.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, 
                                 color: Colors.grey, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'ยังไม่มีรายการธุรกรรม',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _navigateToCreateTransaction,
                              child: const Text('เพิ่มรายการแรก'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...transactions.map((transaction) {
                          final amount = (transaction['amount'] ?? 0).toDouble();
                          final type = transaction['type'] ?? 0;
                          final isIncome = type == 1;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              // เปลี่ยนจาก popup เป็นไปหน้า detail
                              // onTap: () => _navigateToTransactionDetail(transaction),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Leading Icon
                                    CircleAvatar(
                                      backgroundColor: isIncome 
                                          ? Colors.green[100] 
                                          : Colors.red[100],
                                      child: Icon(
                                        isIncome 
                                            ? Icons.arrow_upward 
                                            : Icons.arrow_downward,
                                        color: isIncome ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction['name'] ?? 'ไม่ระบุชื่อ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (transaction['desc'] != null && 
                                              transaction['desc'].toString().isNotEmpty) ...[
                                            Text(
                                              transaction['desc'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Text(
                                            transaction['date'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Trailing Amount
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isIncome ? '+' : '-'}฿${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isIncome ? Colors.green : Colors.red,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6, 
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isIncome 
                                                ? Colors.green.shade50 
                                                : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isIncome ? 'รายรับ' : 'รายจ่าย',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isIncome ? Colors.green : Colors.red,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // เพิ่มไอคอนลูกศร
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                    
                  // Improved Pagination Controls - แยกออกมาข้างนอก
                  if (totalPages > 1 && !isLoading)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // First Page Button
                          IconButton(
                            onPressed: currentPage > 1 ? () => _changePage(1) : null,
                            icon: const Icon(Icons.first_page),
                            tooltip: 'หน้าแรก',
                          ),
                          
                          // Previous Page Button
                          IconButton(
                            onPressed: currentPage > 1 
                                ? () => _changePage(currentPage - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'หน้าก่อนหน้า',
                          ),
                          
                          // Page Numbers (แสดงหน้าใกล้เคียง)
                          ..._buildPageNumbers(),
                          
                          // Next Page Button
                          IconButton(
                            onPressed: currentPage < totalPages 
                                ? () => _changePage(currentPage + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'หน้าถัดไป',
                          ),
                          
                          // Last Page Button
                          IconButton(
                            onPressed: currentPage < totalPages 
                                ? () => _changePage(totalPages) 
                                : null,
                            icon: const Icon(Icons.last_page),
                            tooltip: 'หน้าสุดท้าย',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
  
  // ฟังก์ชันสร้างปุ่มหมายเลขหน้า
  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];
    int startPage = (currentPage - 2).clamp(1, totalPages);
    int endPage = (currentPage + 2).clamp(1, totalPages);
    
    // แสดงหน้าแรกและ ... ถ้าจำเป็น
    if (startPage > 1) {
      pageButtons.add(_buildPageButton(1));
      if (startPage > 2) {
        pageButtons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('...', style: TextStyle(color: Colors.grey)),
        ));
      }
    }
    
    // แสดงหน้าใกล้เคียง
    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(_buildPageButton(i));
    }
    
    // แสดงหน้าสุดท้ายและ ... ถ้าจำเป็น
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageButtons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: Text('...', style: TextStyle(color: Colors.grey)),
        ));
      }
      pageButtons.add(_buildPageButton(totalPages));
    }
    
    return pageButtons;
  }
  
  Widget _buildPageButton(int pageNumber) {
    bool isCurrentPage = pageNumber == currentPage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isCurrentPage ? Colors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _changePage(pageNumber),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '$pageNumber',
              style: TextStyle(
                color: isCurrentPage ? Colors.white : Colors.blue,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}