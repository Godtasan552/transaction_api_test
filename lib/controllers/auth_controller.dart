import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:form_validate/utils/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../utils/navigation_helper.dart';
import '../services/universal_storage.dart';

// AuthController สำหรับจัดการ state ของการ authentication
class AuthController extends GetxController {
  // Observable variables
  final _isLoggedIn = false.obs;
  final _isLoading = false.obs;
  final _currentUser = Rxn<User>();

  // Getters
  bool get isLoggedIn => _isLoggedIn.value;
  bool get isLoading => _isLoading.value;
  User? get currentUser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    // Initialize storage service แล้วตรวจสอบสถานะการล็อกอิน
    _initStorageAndCheckLogin();
  }

  Future<void> _initStorageAndCheckLogin() async {
    try {
      await UniversalStorageService.init();
      _checkLoginStatus();
    } catch (e) {
      debugPrint('Error initializing storage: $e');
    }
  }

  // ตรวจสอบสถานะการล็อกอิน
  Future<void> _checkLoginStatus() async {
    debugPrint('Checking login status...');
    try {
      final token = UniversalStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        // โหลดข้อมูล user จาก storage
        final userData = UniversalStorageService.getUser();
        if (userData != null) {
          final user = User.fromJson(userData);
          _setCurrentUser(user);
        }
        _setLoggedIn(true);
        debugPrint('User is logged in');
      } else {
        _setLoggedIn(false);
        debugPrint('User is not logged in');
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
      _setLoggedIn(false);
    }
  }

  // ฟังก์ชันล็อกอิน
  Future<bool> login({required String email, required String password}) async {
    try {
      _setLoading(true);

      debugPrint('=== LOGIN DEBUG ===');
      debugPrint('Attempting login for: $email');
      debugPrint('Password length: ${password.length}');

      final serviceUrl = '$BASE_URL$LOGIN_ENDPOINT';
      var url = Uri.parse(serviceUrl);
      
      debugPrint('Making request to: $serviceUrl');

      final requestBody = {
        'name': email.trim(),
        'password': password,
      };

      debugPrint('Request body: ${jsonEncode(requestBody)}');

      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout - กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('Parsed response data: $data');

          // ตรวจสอบ structure ของ response
          if (data['data'] == null) {
            throw Exception('Invalid response structure: missing data field');
          }

          final token = data['data']['access'];
          if (token == null || token.isEmpty) {
            throw Exception('Invalid response: missing or empty access token');
          }

          // ดึงข้อมูลผู้ใช้
          final userData = data['data']['auth'];
          if (userData == null) {
            throw Exception('Invalid response: missing auth data');
          }

          // สร้าง User object
          final user = User(
            id: userData['uuid']?.toString() ?? '',
            email: userData['name']?.toString() ?? email,
            firstName: userData['first_name']?.toString() ?? '',
            lastName: userData['last_name']?.toString() ?? '',
            profileImage: userData['profile_image']?.toString(),
          );

          debugPrint('Created user object: ${user.toJson()}');
          _setCurrentUser(user);

          // บันทึก token และข้อมูล user ลงใน local storage
          await UniversalStorageService.saveToken(token);
          await UniversalStorageService.saveUser(user.toJson());

          _setLoggedIn(true);

          debugPrint('Login successful for user: ${user.fullName}');
          NavigationHelper.showSuccessSnackBar('เข้าสู่ระบบสำเร็จ');
          
          // ไม่ต้อง navigate ที่นี่ ให้ UI จัดการเอง
          return true;

        } catch (e) {
          debugPrint('Error parsing login response: $e');
          NavigationHelper.showErrorSnackBar('ข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง');
          return false;
        }
      } else {
        // login ไม่สำเร็จ
        debugPrint('Login failed with status: ${response.statusCode}');
        
        String errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          debugPrint('Could not parse error response: $e');
        }

        NavigationHelper.showErrorSnackBar(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      String errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      
      // แปลงข้อความ error บางอย่างให้เป็นภาษาไทย
      if (e.toString().contains('timeout')) {
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      }
      
      NavigationHelper.showErrorSnackBar(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชันสมัครสมาชิก
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      debugPrint('=== REGISTER DEBUG ===');
      debugPrint('Attempting registration for: $email');
      debugPrint('First name: $firstName, Last name: $lastName');
      debugPrint('Password length: ${password.length}');

      final serviceUrl = '$BASE_URL$REGISTER_ENDPOINT';
      var url = Uri.parse(serviceUrl);
      
      debugPrint('Making request to: $serviceUrl');

      final requestBody = {
        'name': email.trim(),
        'password': password,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      };

      debugPrint('Request body: ${jsonEncode(requestBody)}');
      
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout - กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
        },
      );

      debugPrint('Register response status: ${response.statusCode}');
      debugPrint('Register response headers: ${response.headers}');
      debugPrint('Register response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // แสดงผลสำเร็จ
        debugPrint('Registration successful');
        NavigationHelper.showSuccessSnackBar('สมัครสมาชิกสำเร็จ');
        
        // ไม่ต้อง navigate ที่นี่ ให้ UI จัดการเอง
        return true;
      } else {
        debugPrint('Registration failed with status: ${response.statusCode}');
        
        String errorMessage = 'สมัครสมาชิกไม่สำเร็จ';
        
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('Error data: $errorData');
          
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['errors'] != null) {
            // Handle validation errors
            final errors = errorData['errors'];
            if (errors is Map) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError[0];
              } else {
                errorMessage = firstError.toString();
              }
            }
          }
        } catch (e) {
          debugPrint('Could not parse error response: $e');
        }
        
        NavigationHelper.showErrorSnackBar(errorMessage);
        return false;
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      String errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
      
      // แปลงข้อความ error บางอย่างให้เป็นภาษาไทย
      if (e.toString().contains('timeout')) {
        errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
      }
      
      NavigationHelper.showErrorSnackBar(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชันรีเซ็ตรหัสผ่าน
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);

      // จำลองการเรียก API (ยังไม่มี endpoint จริง)
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('Password reset requested for: $email');
      NavigationHelper.showSuccessSnackBar(
        'ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณแล้ว',
      );

      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชันล็อกเอาต์
  Future<void> logout() async {
    try {
      _setLoading(true);

      debugPrint('Logging out user: ${currentUser?.email}');

      // ลบ token และข้อมูลผู้ใช้
      await UniversalStorageService.deleteToken();
      await UniversalStorageService.deleteUser();
      
      // สามารถเลือกลบข้อมูล transactions ด้วย หรือเก็บไว้
      // await UniversalStorageService.clearTransactions();

      _setLoggedIn(false);
      _setCurrentUser(null);

      debugPrint('Logout successful');
      NavigationHelper.showSuccessSnackBar('ออกจากระบบแล้ว');
      NavigationHelper.toLogin(clearStack: true);
    } catch (e) {
      debugPrint('Logout error: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชันรีเฟรชข้อมูลผู้ใช้
  Future<void> refreshUserData() async {
    try {
      _setLoading(true);
      
      final userData = UniversalStorageService.getUser();
      if (userData != null) {
        final user = User.fromJson(userData);
        _setCurrentUser(user);
        debugPrint('User data refreshed: ${user.fullName}');
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ฟังก์ชันอัปเดตข้อมูลผู้ใช้
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      _setLoading(true);

      final currentUserData = currentUser;
      if (currentUserData == null) return false;

      // สร้างข้อมูลใหม่
      final updatedUser = User(
        id: currentUserData.id,
        email: email ?? currentUserData.email,
        firstName: firstName ?? currentUserData.firstName,
        lastName: lastName ?? currentUserData.lastName,
        profileImage: currentUserData.profileImage,
      );

      // บันทึกข้อมูลใหม่
      await UniversalStorageService.saveUser(updatedUser.toJson());
      _setCurrentUser(updatedUser);

      debugPrint('User profile updated: ${updatedUser.fullName}');
      NavigationHelper.showSuccessSnackBar('อัปเดตข้อมูลสำเร็จ');
      
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading.value = value;
  }

  void _setLoggedIn(bool value) {
    _isLoggedIn.value = value;
  }

  void _setCurrentUser(User? user) {
    _currentUser.value = user;
  }

  // Debug methods
  void printStorageInfo() {
    debugPrint('=== Storage Info ===');
    debugPrint('Has Token: ${UniversalStorageService.hasToken()}');
    debugPrint('Has User: ${UniversalStorageService.hasUser()}');
    debugPrint('All Keys: ${UniversalStorageService.getAllKeys()}');
    debugPrint('Is Logged In: $isLoggedIn');
    debugPrint('Current User: ${currentUser?.email}');
    debugPrint('==================');
  }

  // Test API connectivity
  Future<void> testApiConnection() async {
    try {
      debugPrint('Testing API connection...');
      final response = await http.get(
        Uri.parse(BASE_URL),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      debugPrint('API Test - Status: ${response.statusCode}');
      debugPrint('API Test - Body: ${response.body}');
    } catch (e) {
      debugPrint('API Test Error: $e');
    }
  }
}

// User model 
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImage;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImage,
  });

  String get fullName => '$firstName $lastName'.trim();

  // Convert to/from JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
    );
  }

  // Create copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImage,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, fullName: $fullName}';
  }
}

// Binding สำหรับ Dependency Injection
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}