import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart'; // ตรวจสอบ import

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🎯 Building AppDrawer');
    
    return Drawer(
      child: GetBuilder<AuthController>(
        builder: (authController) {
          debugPrint('🔄 Drawer GetBuilder rebuilding');
          debugPrint('Auth Controller: ${authController != null ? "✅ Found" : "❌ Null"}');
          
          final user = authController.currentUser;
          debugPrint('Current User in Drawer: ${user?.fullName ?? "❌ None"}');

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              UserAccountsDrawerHeader(
                accountName: Text(
                  user?.fullName ?? "Guest User",
                  style: const TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(
                  user?.email ?? "ไม่มีข้อมูลอีเมล",
                  style: const TextStyle(fontSize: 16),
                ),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.person, 
                    size: 40, 
                    color: Colors.white,
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
              
              // Debug Info
              Container(
                color: Colors.yellow[50],
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐛 Drawer Debug:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('User ID: ${user?.id ?? "❌"}'),
                    Text('Email: ${user?.email ?? "❌"}'),
                    Text('Full Name: ${user?.fullName ?? "❌"}'),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Menu Items
              ListTile(
                leading: const Icon(Icons.home, color: Colors.blue),
                title: const Text("หน้าหลัก"),
                onTap: () {
                  debugPrint('🏠 Home menu tapped');
                  Navigator.of(context).pop();
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.account_box, color: Colors.green),
                title: const Text("เกี่ยวกับ"),
                onTap: () {
                  debugPrint('ℹ️ About menu tapped');
                  Navigator.of(context).pop();
                  Get.snackbar(
                    'เกี่ยวกับ',
                    'หน้าเกี่ยวกับแอป',
                    backgroundColor: Colors.blue[100],
                  );
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.grid_3x3_outlined, color: Colors.orange),
                title: const Text("สร้างรายการ"),
                onTap: () {
                  debugPrint('📝 Create Transaction menu tapped');
                  Navigator.of(context).pop();
                  // ใช้ route name แทน AppRoutes ถ้าไม่มี
                  try {
                    // Get.toNamed(AppRoutes.createTransaction);
                    Get.toNamed('/create-transaction'); // หรือใช้ route name โดยตรง
                  } catch (e) {
                    debugPrint('❌ Route error: $e');
                    Get.snackbar(
                      'ข้อผิดพลาด',
                      'ยังไม่มีหน้าสร้างรายการ',
                      backgroundColor: Colors.red[100],
                    );
                  }
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.contact_mail, color: Colors.purple),
                title: const Text("ติดต่อ"),
                onTap: () {
                  debugPrint('📧 Contact menu tapped');
                  Navigator.of(context).pop();
                  Get.snackbar(
                    'ติดต่อ',
                    'หน้าติดต่อ',
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
                  Navigator.of(context).pop();
                  _showLogoutDialog(context, authController);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    debugPrint('🚪 Showing logout dialog');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('❌ Logout cancelled');
              Navigator.of(context).pop();
            },
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('✅ Logout confirmed');
              Navigator.of(context).pop();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}