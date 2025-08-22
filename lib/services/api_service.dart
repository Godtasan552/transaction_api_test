import 'dart:convert';
import 'package:http/http.dart' as http;

// คลาส ApiService เอาไว้จัดการการเรียก API ของเรา
class ApiService {
  // base URL ของ API
  final String baseUrl;
  // สร้าง constructor เพื่อรับ base URL
  ApiService(this.baseUrl);

  // ฟังก์ชัน Login
  // รับ email กับ password แล้วส่งไปให้ server
  // คืนค่าเป็น Map<String, dynamic> ของ response จาก server
  Future<Map<String, dynamic>> login(String email, String password) async {
    // สร้าง URL สำหรับ endpoint /login
    final url = Uri.parse('$baseUrl/login');

    //ส่ง http post request ไปยัง server
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'}, //บอก server ว่าส่ง json
      body: jsonEncode({'name':email, password: password}),// แปลงข้อมูลเป็น json
    );

    // เช็คสถานะการตอบกลับจาก server
    if (response.statusCode == 200) {
      // ถ้าserver ตอบ 200 แปลว่าล็อกอินสำเร็จ
      // แปลง response body (json) เป็น Map
      return jsonDecode(response.body);
    } else {
      // ถ้าไม่ใช่ 200 = ligin failed
      // throw exception เพื่อให้โค้ดข้างจับ error ได้
      throw Exception("Login failed: ${response.body}");
    }
  }

  // function getprofile
  // รับ token ของผู้มใช้ เพื่อดึงข้อมูล profile ล่าสุดจาก  server
  Future<Map<String, dynamic>> getProfile(String token) async {
    // สร้าง URL สำหรับ endpoint /profile
    final url = Uri.parse('$baseUrl/profile');

    // ส่ง HTTP GET request ไปยัง server พร้อม header authorization
    final response = await http.get(
      url,
      headers: {
        'Authorization':'Bearer $token', // ส่ง JWT token ไปยืนยันตัตน
      },
    );

    // เช็คสถานะการตอบกลับจาก server
    if (response.statusCode == 200) {
      // server ตอบ 200 แปลว่าดึงข้อมูล profile สำเร็จ
      return jsonDecode(response.body); // แปลง response body เป็น Map
    } else {
      // ถ้าไม่ใช่ 200 = get profile failed
      throw Exception("Get profile failed: ${response.body}");
    }
  
  }
}