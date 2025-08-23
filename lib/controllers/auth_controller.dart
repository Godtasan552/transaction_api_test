import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:form_validate/utils/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:form_validate/services/api_service.dart';
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
        final requestBody = {
          'email': email,
          'password': password,
        };
        debugPrint('Request body: ${jsonEncode(requestBody)}');
        final response = await ApiService.post(LOGIN_ENDPOINT, requestBody);
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final token = data['token'] ?? data['access_token'];
          final user = data['user'] ?? data['data'] ?? {};
          if (token != null && user != null) {
            await UniversalStorageService.saveToken(token);
            await UniversalStorageService.saveUser(user);
            _setLoggedIn(true);
            _setCurrentUser(User.fromJson(user));
            return true;
          } else {
            NavigationHelper.showErrorSnackBar('ข้อมูลผู้ใช้หรือ token ไม่ถูกต้อง');
            return false;
          }
        } else {
          String msg = 'เข้าสู่ระบบไม่สำเร็จ: ${response.body}';
          NavigationHelper.showErrorSnackBar(msg);
          return false;
        }
      } catch (e) {
        debugPrint('Login error: $e');
        String errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
        if (e.toString().contains('timeout')) {
          errorMessage = 'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง';
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
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
        final requestBody = {
          'name': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        };
        debugPrint('Making request to: $BASE_URL$REGISTER_ENDPOINT');
        debugPrint('Request body: ${jsonEncode(requestBody)}');
        final response = await ApiService.post(REGISTER_ENDPOINT, requestBody);
        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        if (response.statusCode == 200 || response.statusCode == 201) {
          return true;
        } else {
          // พยายามแปล error message จาก response
          String errorMsg = 'สมัครสมาชิกไม่สำเร็จ';
          try {
            final errorData = jsonDecode(response.body);
            if (errorData is Map) {
              if (errorData['message'] != null) {
                errorMsg = errorData['message'].toString();
              } else if (errorData['error'] != null) {
                errorMsg = errorData['error'].toString();
              } else if (errorData['errors'] != null) {
                final errors = errorData['errors'];
                if (errors is Map && errors.isNotEmpty) {
                  final firstError = errors.values.first;
                  if (firstError is List && firstError.isNotEmpty) {
                    errorMsg = firstError[0].toString();
                  } else {
                    errorMsg = firstError.toString();
                  }
                }
              }
            }
          } catch (_) {}
          NavigationHelper.showErrorSnackBar(errorMsg);
          return false;
        }
      } catch (e) {
        debugPrint('Registration error: $e');
        NavigationHelper.showErrorSnackBar('เกิดข้อผิดพลาดในการสมัครสมาชิก: ${e.toString()}');
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