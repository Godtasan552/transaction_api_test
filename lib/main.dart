import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/regis.dart';
import 'screens/forget_pass.dart';
import 'screens/home.dart'; // สมมติว่ามีหน้า Home
import 'controllers/auth_controller.dart';
import 'controllers/trans_controller.dart';
import 'services/universal_storage.dart';
import 'components/drawer.dart';

void main() async {
  // ต้องเรียก ensureInitialized ก่อนใช้ SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage service
  await UniversalStorageService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Form Validate App',
      theme: ThemeData(
        // กำหนด theme ของแอป
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        
        // กำหนดสไตล์ของ ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        // กำหนดสไตล์ของ TextFormField
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        
        // กำหนดสไตล์ของ AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
      ),
      
      // กำหนด initial route และ routes
      initialRoute: '/splash',
      getPages: [
        // Splash Screen
        GetPage(
          name: '/splash',
          page: () => const SplashScreen(),
        ),
        
        // Authentication Pages
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/forget-password',
          page: () => const ForgetPasswordScreen(),
        ),
        
        // Main App Pages
        GetPage(
          name: '/home',
          page: () => const HomeScreen(),
          bindings: [
            AuthBinding(),
            TransactionBinding(),
          ],
        ),
        
        // Transaction Pages (ถ้ามี)
        // GetPage(
        //   name: '/transaction/add',
        //   page: () => const AddTransactionScreen(),
        //   binding: TransactionBinding(),
        // ),
        // GetPage(
        //   name: '/transaction/edit',
        //   page: () => const EditTransactionScreen(),
        //   binding: TransactionBinding(),
        // ),
      ],
      
      // กำหนด default transition
      defaultTransition: Transition.cupertino,
      
      // กำหนด duration ของ transition
      transitionDuration: const Duration(milliseconds: 300),
      
      // Debug settings
      debugShowCheckedModeBanner: false,
      
      // Error handling
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const NotFoundScreen(),
      ),
    );
  }
}

// ✅ หน้า Home Screen ที่มี Drawer
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 Building HomeScreen with Drawer');
    
    return GetBuilder<AuthController>(
      builder: (authController) {
        return GetBuilder<TransactionController>(
          builder: (transactionController) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('หน้าหลัก'),
                automaticallyImplyLeading: true, // ✅ แสดง drawer icon
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => transactionController.refreshData(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => authController.logout(),
                  ),
                ],
              ),
              // ✅ เพิ่ม Drawer
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
                        debugPrint('🏠 Home menu tapped');
                        Navigator.pop(context);
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.account_box, color: Colors.green),
                      title: const Text("เกี่ยวกับ"),
                      onTap: () {
                        debugPrint('ℹ️ About menu tapped');
                        Navigator.pop(context);
                        Get.snackbar(
                          'เกี่ยวกับ',
                          'ข้อมูลเกี่ยวกับแอป',
                          backgroundColor: Colors.green[100],
                        );
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.add, color: Colors.orange),
                      title: const Text("เพิ่มรายการ"),
                      onTap: () {
                        debugPrint('➕ Add transaction menu tapped');
                        Navigator.pop(context);
                        _showAddTransactionDialog(context, 1);
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.list, color: Colors.purple),
                      title: const Text("ดูรายการทั้งหมด"),
                      onTap: () {
                        debugPrint('📋 View all transactions menu tapped');
                        Navigator.pop(context);
                        Get.snackbar(
                          'รายการทั้งหมด',
                          'ฟีเจอร์กำลังพัฒนา',
                          backgroundColor: Colors.purple[100],
                        );
                      },
                    ),
                    
                    const Divider(),
                    
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text("ออกจากระบบ"),
                      onTap: () {
                        debugPrint('🚪 Logout menu tapped');
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
                      // Welcome Message
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สวัสดี ${authController.currentUser?.firstName ?? 'ผู้ใช้'}!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ยินดีต้อนรับสู่แอปจัดการรายรับรายจ่าย',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Balance Summary
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
                      
                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to add income
                                _showAddTransactionDialog(context, 1);
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
                                // Navigate to add expense
                                _showAddTransactionDialog(context, -1);
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
                      
                      // Recent Transactions
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
                                      // Navigate to all transactions
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
                                      child: Text('ยังไม่มีรายการธุรกรรม'),
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
  
  // ✅ เพิ่ม logout dialog
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
  
  // Dialog สำหรับเพิ่มธุรกรรม
  void _showAddTransactionDialog(BuildContext context, int type) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 1 ? 'เพิ่มรายรับ' : 'เพิ่มรายจ่าย'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อรายการ',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อรายการ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงิน',
                  prefixIcon: Icon(Icons.money),
                  suffixText: '฿',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกจำนวนเงิน';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'กรุณากรอกจำนวนเงินให้ถูกต้อง';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุ (ไม่บังคับ)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final transactionController = Get.find<TransactionController>();
                transactionController.addTransaction(
                  name: nameController.text,
                  amount: double.parse(amountController.text),
                  type: type,
                  description: descController.text.isEmpty ? null : descController.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}

// หน้า Not Found
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ไม่พบหน้า'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'ไม่พบหน้าที่ต้องการ',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'กรุณาตรวจสอบ URL หรือกลับไปหน้าหลัก',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}