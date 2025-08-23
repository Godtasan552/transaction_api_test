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
  double totalBalance = 0;
  
  // เพิ่มตัวแปรสำหรับโหลดยอดรวมทั้งหมด
  bool isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // โหลดข้อมูลเริ่มต้น
  Future<void> _loadInitialData() async {
    // โหลดข้อมูลทั้งคู่พร้อมกัน
    await Future.wait([
      _loadTransactions(),
      _loadSummaryData(),
    ]);
  }

  // โหลดรายการธุรกรรม (แบ่งหน้า)
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
          totalPages = data['meta']['totalPages'] ?? 1; // เปลี่ยนจาก totalPages เป็น meta.totalPages
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

  // โหลดยอดรวมทั้งหมด - วิธีใหม่ที่มีประสิทธิภาพมากขึ้น
  Future<void> _loadSummaryData() async {
    setState(() {
      isLoadingSummary = true;
    });

    try {
      await UniversalStorageService.init();
      final token = UniversalStorageService.getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          isLoadingSummary = false;
        });
        return;
      }

      // วิธี 1: ถ้า Backend มี Summary Endpoint (แนะนำ)
      // final summaryUrl = Uri.parse(
      //   "https://transactions-cs.vercel.app/api/transaction/summary",
      // );

      // วิธี 2: ใช้ pagination ขนาดใหญ่เพื่อดึงข้อมูลทั้งหมดในครั้งเดียว
      final summaryUrl = Uri.parse(
        "https://transactions-cs.vercel.app/api/transaction?page=1&limit=999999", // ใช้ limit ใหญ่มาก
      );

      final response = await http.get(
        summaryUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Summary request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ตรวจสอบว่ามี summary ใน response หรือไม่
        if (data['summary'] != null) {
          // วิธี 1: ถ้า Backend ส่ง summary มาให้
          final summary = data['summary'];
          setState(() {
            totalIncome = (summary['totalIncome'] ?? 0).toDouble();
            totalExpense = (summary['totalExpense'] ?? 0).toDouble();
            totalBalance = (summary['totalBalance'] ?? 0).toDouble();
          });
        } else {
          // วิธี 2: คำนวณจากข้อมูลทั้งหมดที่ได้รับ
          final allTransactions = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _calculateTotalFromAllTransactions(allTransactions);
        }
      } else {
        // ถ้าเรียก summary ไม่ได้ ให้ใช้ข้อมูลจาก transactions ปัจจุบัน
        _calculateTotalsFromCurrentPage();
      }
    } catch (e) {
      print('Error loading summary: $e');
      // ถ้าโหลด summary ไม่ได้ ให้คำนวณจากรายการปัจจุบัน
      _calculateTotalsFromCurrentPage();
    } finally {
      setState(() {
        isLoadingSummary = false;
      });
    }
  }

  // คำนวณยอดรวมจากรายการทั้งหมด
  void _calculateTotalFromAllTransactions(List<Map<String, dynamic>> allTransactions) {
    double incomeSum = 0;
    double expenseSum = 0;
    
    for (var transaction in allTransactions) {
      final amount = (transaction['amount'] ?? 0).toDouble();
      final type = transaction['type'] ?? 0;
      
      if (type == 1) {
        incomeSum += amount;
      } else if (type == -1) { // เพิ่มการตรวจสอบ type == -1 อย่างชัดเจน
        expenseSum += amount;
      }
    }
    
    setState(() {
      totalIncome = incomeSum;
      totalExpense = expenseSum;
      totalBalance = incomeSum - expenseSum;
    });
  }

  // คำนวณยอดรวมจากหน้าปัจจุบัน (ใช้เป็น fallback) - แต่แสดงคำเตือน
  void _calculateTotalsFromCurrentPage() {
    double incomeSum = 0;
    double expenseSum = 0;
    
    for (var transaction in transactions) {
      final amount = (transaction['amount'] ?? 0).toDouble();
      final type = transaction['type'] ?? 0;
      
      if (type == 1) {
        incomeSum += amount;
      } else if (type == -1) {
        expenseSum += amount;
      }
    }
    
    setState(() {
      totalIncome = incomeSum;
      totalExpense = expenseSum;
      totalBalance = incomeSum - expenseSum;
    });
  }

  Future<void> _navigateToCreateTransaction() async {
    final result = await Get.toNamed(AppRoutes.createTransaction);
    
    // ถ้าสร้างธุรกรรมสำเร็จ รีเฟรชข้อมูลทั้งหมด
    if (result == true) {
      _loadInitialData();
    }
  }

  void _changePage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
      });
      _loadTransactions(); // โหลดแค่รายการธุรกรรม ไม่ต้องโหลด summary ใหม่
    }
  }

  // รีเฟรชข้อมูลทั้งหมด
  Future<void> _refreshAllData() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAllData,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
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
                  
                  // Summary Cards - แสดงยอดรวมที่ถูกต้อง
                  // Balance Card (แสดงใหญ่)
                  Card(
                    color: totalBalance >= 0 ? Colors.blue[50] : Colors.orange[50],
                    elevation: 4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet, 
                                color: totalBalance >= 0 ? Colors.blue : Colors.orange, 
                                size: 32
                              ),
                              if (isLoadingSummary) ...[
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ],
                            ],
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
                          // แสดงคำเตือนถ้าไม่ได้โหลด summary แบบเต็ม
                          if (!isLoadingSummary && totalPages > 1 && transactions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ยอดรวมทั้งหมด',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_upward, 
                                         color: Colors.green, size: 24),
                                    if (isLoadingSummary) ...[
                                      const SizedBox(width: 4),
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_downward, 
                                         color: Colors.red, size: 24),
                                    if (isLoadingSummary) ...[
                                      const SizedBox(width: 4),
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
                              onPressed: _refreshAllData,
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
                              // TODO: เพิ่มการไปหน้า detail ในอนาคต
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
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                    
                  // Improved Pagination Controls
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
                          
                          // Page Numbers
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