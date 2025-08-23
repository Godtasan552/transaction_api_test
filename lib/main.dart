import 'package:flutter/material.dart';
import 'package:form_validate/screens/create_transaction.dart';
import 'package:get/get.dart';
import 'screens/splash_screen.dart';
import 'screens/login.dart';
import 'screens/regis.dart';
import 'screens/forget_pass.dart';
import 'screens/home.dart'; // สมมติว่ามีหน้า Home
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

        GetPage(
          name: '/create-transaction',
          page: () => const CreateTransactionPage(),
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