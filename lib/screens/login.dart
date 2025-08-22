import 'package:flutter/material.dart';
import 'package:form_validate/controllers/auth_controller.dart';
import 'package:get/get.dart';
import '../utils/navigation_helper.dart';
import 'package:flutter/foundation.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // เพิ่มข้อมูลตัวอย่างสำหรับ testing (ลบออกเมื่อ production)
    _emailController.text = 'test@example.com';
    _passwordController.text = 'password123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // จำลองการ Login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      AuthController authController = Get.put(AuthController());
      
      // เพิ่ม debug information
      debugPrint('Starting login process...');
      debugPrint('Email: ${_emailController.text}');
      debugPrint('Password length: ${_passwordController.text.length}');
      
      bool loginSuccess = await authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      debugPrint('Login result: $loginSuccess');

      if (loginSuccess) {
        // นำทางไปหน้า Home
        debugPrint('Navigating to home...');
        NavigationHelper.toHome(clearStack: true);
      } else {
        debugPrint('Login failed');
        // Error message จะถูกแสดงใน AuthController แล้ว
      }
    } catch (e) {
      debugPrint('Login exception in UI: $e');
      NavigationHelper.showErrorSnackBar(
        'เกิดข้อผิดพลาดในการเข้าสู่ระบบ กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Test API connection
  Future<void> _testApiConnection() async {
    AuthController authController = Get.put(AuthController());
    await authController.testApiConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบ'),
        automaticallyImplyLeading: false, // ซ่อนปุ่ม back
        actions: [
          // Debug button - ลบออกเมื่อ production
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _testApiConnection,
              tooltip: 'Test API',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 40),

                // Welcome Text
                Text(
                  'ยินดีต้อนรับ',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'กรุณาเข้าสู่ระบบเพื่อดำเนินการต่อ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อผู้ใช้ / อีเมล',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อผู้ใช้หรืออีเมล';
                    }
                    // ตรวจสอบรูปแบบอีเมลแบบง่าย
                    if (value.contains('@') && !value.contains('@.')) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'กรุณากรอกอีเมลให้ถูกต้อง';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    if (value.length < 6) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'เข้าสู่ระบบ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => NavigationHelper.toRegister(),
                      child: const Text('สร้างบัญชีใหม่'),
                    ),
                    TextButton(
                      onPressed: () => NavigationHelper.toForgetPassword(),
                      child: const Text('ลืมรหัสผ่าน?'),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Debug info - ลบออกเมื่อ production
                if (kDebugMode) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Info (Development Only)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Test Account:\nEmail: test@example.com\nPassword: password123',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}