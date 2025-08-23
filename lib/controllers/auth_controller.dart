import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:form_validate/utils/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:form_validate/services/api_service.dart';
import '../utils/navigation_helper.dart';
import '../services/jwt_storage.dart';


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
    _checkLoginStatus();
  }

  // ตรวจสอบสถานะการล็อกอิน (เช็ค token ใน JwtStorage)
  Future<void> _checkLoginStatus() async {
    debugPrint('Checking login status...');
    try {
      final token = await JwtStorage.getToken();
      if (token != null && token.isNotEmpty) {
        _setLoggedIn(true);
        // ไม่โหลด user จาก storage ให้ไปโหลดจาก API ถ้าต้องการ
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


  // ฟังก์ชันล็อกอิน (ใช้ name, password ตาม backend)
  Future<bool> login({required String name, required String password}) async {
    try {
      _setLoading(true);
      debugPrint('=== LOGIN DEBUG ===');
      debugPrint('Attempting login for: $name');
      debugPrint('Password length: ${password.length}');
      final requestBody = {
        'name': name,
        'password': password,
      };
      debugPrint('Request body: ${jsonEncode(requestBody)}');
      final response = await ApiService().post('/auth/login', requestBody, withAuth: false);
      debugPrint('Response status: [32m${response.statusCode}[0m');
      debugPrint('Response body: ${response.body}');
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']?['access'];
        final userJson = data['data']?['auth'];
        if (token != null && userJson != null) {
          await JwtStorage.saveToken(token);
          _setLoggedIn(true);
          _setCurrentUser(User.fromJson(userJson));
          NavigationHelper.toHome(clearStack: true);
          return true;
        } else {
          NavigationHelper.showErrorSnackBar('ข้อมูลผู้ใช้หรือ token ไม่ถูกต้อง');
          return false;
        }
      } else {
        String msg = data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ';
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


  // ฟังก์ชันสมัครสมาชิก (name, first_name, last_name, password)
  Future<bool> register({
    required String name,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      _setLoading(true);
      final response = await ApiService().post('/auth/register', {
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      }, withAuth: false);
      final data = json.decode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        NavigationHelper.showSuccessSnackBar('สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ');
        return true;
      } else {
        String msg = data['message'] ?? 'สมัครสมาชิกไม่สำเร็จ';
        NavigationHelper.showErrorSnackBar(msg);
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


  // ฟังก์ชันรีเซ็ตรหัสผ่าน (mock, ยังไม่มี endpoint จริง)
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('Password reset requested for: $email');
      NavigationHelper.showSuccessSnackBar('ส่งลิงก์รีเซ็ตรหัสผ่านไปยังอีเมลของคุณแล้ว');
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
    await ApiService().logout();
    _setLoggedIn(false);
    _setCurrentUser(null);
  }


  // ฟังก์ชันรีเฟรชข้อมูลผู้ใช้ (ควรดึงจาก API จริง)
  Future<void> refreshUserData() async {
    // TODO: เรียก API /api/user/profile ถ้ามี endpoint
    // ตัวอย่าง mock:
    try {
      _setLoading(true);
      // final response = await ApiService().get('/user/profile');
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   _setCurrentUser(User.fromJson(data['data']));
      // }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    } finally {
      _setLoading(false);
    }
  }


  // ฟังก์ชันอัปเดตข้อมูลผู้ใช้ (mock, ยังไม่มี endpoint จริง)
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      _setLoading(true);
      final currentUserData = currentUser;
      if (currentUserData == null) return false;
      final updatedUser = currentUserData.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
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
  void printStorageInfo() async {
    debugPrint('=== Storage Info ===');
    final token = await JwtStorage.getToken();
    debugPrint('Has Token: ${token != null && token.isNotEmpty}');
    debugPrint('Is Logged In: $isLoggedIn');
    debugPrint('Current User: ${currentUser?.fullName}');
    debugPrint('==================');
  }


  // Test API connectivity
  Future<void> testApiConnection() async {
    try {
      debugPrint('Testing API connection...');
      final response = await ApiService().get('/transaction');
      debugPrint('API Test - Status: ${response.statusCode}');
      debugPrint('API Test - Body: ${response.body}');
    } catch (e) {
      debugPrint('API Test Error: $e');
    }
  }
}


// User model (ตาม backend)
class User {
  final String uuid;
  final String name;
  final String firstName;
  final String lastName;
  final String? email;

  User({
    required this.uuid,
    required this.name,
    required this.firstName,
    required this.lastName,
    this.email,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }

  User copyWith({
    String? uuid,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }

  @override
  String toString() {
    return 'User{uuid: $uuid, name: $name, fullName: $fullName}';
  }
}

// Binding สำหรับ Dependency Injection
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}