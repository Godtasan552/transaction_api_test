import 'package:flutter/material.dart';
import 'package:form_validate/screens/create_transaction.dart';
// import 'package:form_validate/screens/create_transaction.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/trans_controller.dart';
import '../routes/app_routes.dart';
import '../routes/app_pages.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏠 Building HomeScreen');
    final authController = Get.find<AuthController>();
    final transactionController = Get.find<TransactionController>();
  return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => transactionController.refreshData(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text("สร้างรายการ"),
              onTap: () {
                print('➕ Create transaction menu tapped');
                Navigator.pop(context);
                Get.toNamed('/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.purple),
              title: const Text("ดูรายการทั้งหมด"),
              onTap: () {
                print('📋 View all transactions menu tapped');
                Navigator.pop(context);
                Get.snackbar(
                  'รายการทั้งหมด',
                  'ฟีเจอร์กำลังพัฒนา',
                  backgroundColor: Colors.purple[100],
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.orange),
              title: const Text("เกี่ยวกับ"),
              onTap: () {
                print('ℹ️ About menu tapped');
                Navigator.pop(context);
                Get.snackbar(
                  'เกี่ยวกับ',
                  'แอปจัดการรายรับรายจ่าย v1.0',
                  backgroundColor: Colors.orange[100],
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("ออกจากระบบ"),
              onTap: () {
                print('🚪 Logout menu tapped');
                Navigator.pop(context);
                _showLogoutDialog(context, authController);
              },
            ),
          ],
        ),
  ),
  body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Balance Summary Card (ใช้ Obx เฉพาะกับค่าที่เป็น Rx จริง)
              Obx(() {
                final balance = transactionController.balance;
                final totalIncome = transactionController.totalIncome;
                final totalExpense = transactionController.totalExpense;
                return Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ยอดคงเหลือ',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${balance.toStringAsFixed(2)} ฿',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'รายรับ',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${totalIncome.toStringAsFixed(2)} ฿',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'รายจ่าย',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${totalExpense.toStringAsFixed(2)} ฿',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // Recent Transactions List (อัปเดตอัตโนมัติด้วย Obx)
              Obx(() {
                final paginatedTransactions = transactionController.paginatedTransactions;
                if (paginatedTransactions.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีรายการธุรกรรม'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รายการล่าสุด',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...paginatedTransactions.map((transaction) {
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: transaction.type == 1
                                ? Colors.green[50]
                                : Colors.red[50],
                            child: Icon(
                              transaction.type == 1
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: transaction.type == 1
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          title: Text(transaction.name),
                          subtitle: Text(transaction.formattedDate),
                          trailing: Text(
                            '${transaction.type == 1 ? '+' : '-'}${transaction.formattedAmount}',
                            style: TextStyle(
                              color: transaction.type == 1
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            // ไปหน้ารายละเอียด
                            Get.toNamed('/detail', arguments: transaction);
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: transactionController.prevPage,
                          child: const Text('⬅️ ก่อนหน้า'),
                        ),
                        Obx(() => Text(
                              'หน้า ${transactionController.currentPage} / ${transactionController.totalPages}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )),
                        TextButton(
                          onPressed: transactionController.nextPage,
                          child: const Text('ถัดไป ➡️'),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const CreateTransactionPage()); // ใส่ widget ที่ต้องการ
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        tooltip: 'ไปหน้าใหม่',
      ),
    );
  }
  }

  // Logout Dialog
  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authController.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
// end of HomeScreen
