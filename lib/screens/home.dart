import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:form_validate/components/drawer.dart';
import '../controllers/auth_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: Drawer(),
      body: Obx(() {
        final user = authController.currentUser;
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[100],
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'สวัสดี ${user?.fullName ?? "ผู้ใช้"}!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                user?.email ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'ยินดีต้อนรับสู่หน้าหลัก!',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    'สำเร็จ',
                    'คุณได้กดปุ่มแล้ว!',
                    backgroundColor: Colors.green[100],
                    colorText: Colors.green[800],
                  );
                },
                child: const Text('กดที่นี่'),
              ),
            ],
          ),
        );
      }),
    );
  }
}