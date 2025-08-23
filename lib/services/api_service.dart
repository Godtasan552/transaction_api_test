import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'https://transactions-cs.vercel.app/api';
  
  // สำหรับแก้ปัญหา CORS บน Web
  static const String corsProxy = 'https://cors-anywhere.herokuapp.com/';
  static const String alternativeCorsProxy = 'https://api.allorigins.win/raw?url=';
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (kIsWeb) 'Access-Control-Allow-Origin': '*',
  };
  
  static String getApiUrl(String endpoint) {
    // สำหรับ Web ใช้ CORS proxy
    if (kIsWeb) {
      // ลองใช้ cors-anywhere ก่อน
      return '$corsProxy$baseUrl$endpoint';
    }
    // สำหรับ Mobile ใช้ URL ตรง
    return '$baseUrl$endpoint';
  }
  
  static String getAlternativeApiUrl(String endpoint) {
    // Fallback option สำหรับ Web
    if (kIsWeb) {
      return '${alternativeCorsProxy}${Uri.encodeComponent('$baseUrl$endpoint')}';
    }
    return '$baseUrl$endpoint';
  }
  
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    try {
      print('🌐 Making API request to: ${getApiUrl(endpoint)}');
      print('📤 Request body: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse(getApiUrl(endpoint)),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      
      return response;
      
    } catch (e) {
      print('❌ Primary request failed: $e');
      
      // ถ้า Web และ request แรกล้มเหลว ลอง alternative proxy
      if (kIsWeb) {
        try {
          print('🔄 Trying alternative proxy...');
          final alternativeResponse = await http.post(
            Uri.parse(getAlternativeApiUrl(endpoint)),
            headers: headers,
            body: jsonEncode(body),
          ).timeout(const Duration(seconds: 10));
          
          print('📥 Alternative response status: ${alternativeResponse.statusCode}');
          return alternativeResponse;
          
        } catch (alternativeError) {
          print('❌ Alternative request also failed: $alternativeError');
        }
      }
      
      rethrow;
    }
  }
  
  static Future<http.Response> get(String endpoint) async {
    try {
      print('🌐 Making GET request to: ${getApiUrl(endpoint)}');
      
      final response = await http.get(
        Uri.parse(getApiUrl(endpoint)),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('📥 Response status: ${response.statusCode}');
      return response;
      
    } catch (e) {
      print('❌ GET request failed: $e');
      
      if (kIsWeb) {
        try {
          final alternativeResponse = await http.get(
            Uri.parse(getAlternativeApiUrl(endpoint)),
            headers: headers,
          ).timeout(const Duration(seconds: 10));
          
          return alternativeResponse;
        } catch (alternativeError) {
          print('❌ Alternative GET request failed: $alternativeError');
        }
      }
      
      rethrow;
    }
  }
}