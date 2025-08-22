import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../components/drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏠 Building HomeScreen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // ✅ ใช้ Drawer แบบง่ายที่แน่ใจว่าจะทำงาน
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'เมนูหลัก',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('หน้าหลัก'),
              onTap: () {
                print('🏠 Home menu tapped');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('เกี่ยวกับ'),
              onTap: () {
                print('ℹ️ About menu tapped');
                Navigator.pop(context);
                Get.snackbar('เกี่ยวกับ', 'หน้าเกี่ยวกับแอป');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('สร้างรายการ'),
              onTap: () {
                print('➕ Create menu tapped');
                Navigator.pop(context);
                Get.snackbar('สร้างรายการ', 'ฟีเจอร์กำลังพัฒนา');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('ออกจากระบบ'),
              onTap: () {
                print('🚪 Logout menu tapped');
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: GetBuilder<AuthController>(
        builder: (authController) {
          print('🔄 HomeScreen body rebuilding');
          final user = authController.currentUser;
          
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ปุ่มทดสอบเปิด Drawer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.info, color: Colors.orange),
                        const SizedBox(height: 8),
                        const Text(
                          'ทดสอบ Drawer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            print('🔧 Manual drawer open button pressed');
                            Scaffold.of(context).openDrawer();
                          },
                          icon: const Icon(Icons.menu),
                          label: const Text('เปิด Drawer ด้วยมือ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // ข้อมูลผู้ใช้
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
                            'สวัสดี ${user?.fullName ?? "ผู้ใช้"}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.email ?? "ไม่มีข้อมูลอีเมล",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Debug Info
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
                        Text('User Name: ${user?.fullName ?? "None"}'),
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
                  
                  const Spacer(),
                  
                  // ปุ่มต่างๆ
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Get.snackbar(
                              'ทดสอบ',
                              'ปุ่มทำงานได้ปกติ',
                              backgroundColor: Colors.green[100],
                            );
                          },
                          child: const Text('ทดสอบ'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            print('🔧 Opening drawer from button');
                            Scaffold.of(context).openDrawer();
                          },
                          child: const Text('เปิดเมนู'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
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
              Get.find<AuthController>().logout();
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