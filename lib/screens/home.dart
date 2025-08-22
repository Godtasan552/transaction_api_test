import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/trans_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏠 Building HomeScreen');
    
    return GetBuilder<AuthController>(
      builder: (authController) {
        return GetBuilder<TransactionController>(
          builder: (transactionController) {
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
              // Drawer Menu
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(
                        authController.currentUser?.fullName ?? "ผู้ใช้",
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      accountEmail: Text(
                        authController.currentUser?.email ?? "ไม่มีข้อมูลอีเมล",
                        style: const TextStyle(fontSize: 16),
                      ),
                      currentAccountPicture: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person, 
                          size: 40, 
                          color: Colors.blue,
                        ),
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.home, color: Colors.blue),
                      title: const Text("หน้าหลัก"),
                      onTap: () {
                        print('🏠 Home menu tapped');
                        Navigator.pop(context);
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.green),
                      title: const Text("สร้างรายการ"),
                      onTap: () {
                        print('➕ Create transaction menu tapped');
                        Navigator.pop(context);
                        // Navigate to create page
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
                      // Welcome Message Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.blue[100],
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'สวัสดี ${authController.currentUser?.fullName ?? "ผู้ใช้"}!',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                authController.currentUser?.email ?? "ไม่มีข้อมูลอีเมล",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ยินดีต้อนรับสู่แอปจัดการรายรับรายจ่าย',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Balance Summary Card
                      Card(
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
                                    '${transactionController.balance.toStringAsFixed(2)} ฿',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: transactionController.balance >= 0 
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
                                          '${transactionController.totalIncome.toStringAsFixed(2)} ฿',
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
                                          '${transactionController.totalExpense.toStringAsFixed(2)} ฿',
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
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quick Actions - Navigate to Create Page
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                print('➕ Navigate to create income page');
                                Get.toNamed('/create', arguments: {'type': 'income'});
                              },
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              label: const Text('เพิ่มรายรับ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[50],
                                foregroundColor: Colors.green[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                print('➖ Navigate to create expense page');
                                Get.toNamed('/create', arguments: {'type': 'expense'});
                              },
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              label: const Text('เพิ่มรายจ่าย'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Recent Transactions Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'รายการล่าสุด',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.snackbar(
                                        'รายการทั้งหมด',
                                        'ฟีเจอร์กำลังพัฒนา',
                                        backgroundColor: Colors.blue[100],
                                      );
                                    },
                                    child: const Text('ดูทั้งหมด'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Obx(() {
                                final recentTransactions = transactionController.transactions
                                    .take(5)
                                    .toList();
                                
                                if (recentTransactions.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.receipt_long,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'ยังไม่มีรายการธุรกรรม',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'เริ่มต้นโดยการเพิ่มรายรับหรือรายจ่าย',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                return Column(
                                  children: recentTransactions.map((transaction) {
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
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
                                    );
                                  }).toList(),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Debug Info (Optional - can be removed in production)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.yellow[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.yellow),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🐛 Debug Info',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text('Current Route: ${Get.currentRoute}'),
                            Text('User Logged In: ${authController.isLoggedIn}'),
                            Text('User Name: ${authController.currentUser?.fullName ?? "None"}'),
                            Text('Transactions Count: ${transactionController.transactions.length}'),
                            const SizedBox(height: 8),
                            const Text(
                              'ดูใน Console เพื่อดู debug messages',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
}