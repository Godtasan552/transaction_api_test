import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/regis.dart';
import 'screens/forget_pass.dart';
import 'screens/home.dart';
// import 'screens/create_transaction.dart'; // เพิ่มเมื่อสร้างหน้า create แล้ว
import 'controllers/auth_controller.dart';
import 'controllers/trans_controller.dart';
import 'services/universal_storage.dart';

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
        
        // Transaction Pages
        // GetPage(
        //   name: '/create',
        //   page: () => const CreateTransactionScreen(),
        //   binding: TransactionBinding(),
        // ),
        // GetPage(
        //   name: '/transaction/list',
        //   page: () => const TransactionListScreen(),
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

// Auth Binding
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}

// Transaction Binding  
class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionController>(() => TransactionController());
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่พบหน้าที่ต้องการ',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'กรุณาตรวจสอบ URL หรือกลับไปหน้าหลัก',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/home'),
              icon: const Icon(Icons.home),
              label: const Text('กลับหน้าหลัก'),
            ),
          ],
        ),
      ),
    );
  }
}