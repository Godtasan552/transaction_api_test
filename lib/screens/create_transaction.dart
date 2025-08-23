import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_validate/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../services/universal_storage.dart';

class CreateTransactionPage extends StatefulWidget {
  const CreateTransactionPage({super.key});

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionPageState();
}

class _CreateTransactionPageState extends State<CreateTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  int _type = -1; // -1 = expense, 1 = income
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  bool _storageInitialized = false;

  @override
  void initState() {
    super.initState();
    _initStorageService();
  }

  Future<void> _initStorageService() async {
    try {
      await UniversalStorageService.init();
      setState(() {
        _storageInitialized = true;
      });
      debugPrint("UniversalStorageService initialized successfully");
    } catch (e) {
      debugPrint("Failed to initialize UniversalStorageService: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาดในการเริ่มต้นระบบ: $e"),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_storageInitialized) {
      Get.snackbar(
        'ข้อผิดพลาด',
        'ระบบยังไม่พร้อมใช้งาน กรุณาลองใหม่อีกครั้ง',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final token = UniversalStorageService.getToken();

      // ตรวจสอบ token
      if (token == null || token.isEmpty) {
        debugPrint("Token is null or empty");
        if (mounted) {
          Get.snackbar(
            'ข้อผิดพลาด',
            'กรุณาเข้าสู่ระบบใหม่',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          Get.offAllNamed('/login');
        }
        return;
      }

      final url = Uri.parse(
        "https://transactions-cs.vercel.app/api/transaction",
      );

      final body = {
        "name": _nameController.text.trim(),
        "desc": _descController.text.trim(),
        "amount": int.tryParse(_amountController.text) ?? 0,
        "type": _type,
        "date": _selectedDate.toIso8601String().split("T")[0],
      };

      // Debug log
      debugPrint("====CREATE TRANSACTION DEBUG====");
      debugPrint("Token exists: ${token.isNotEmpty}");
      debugPrint("POST $url");
      debugPrint("Body: ${jsonEncode(body)}");

      final res = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout - กรุณาลองใหม่อีกครั้ง');
            },
          );

      debugPrint("Status Code: ${res.statusCode}");
      debugPrint("Response Body: ${res.body}");

      if (res.statusCode == 201) {
        debugPrint("Transaction created successfully");
        if (mounted) {
          // แสดง SnackBar แจ้งความสำเร็จ
          Get.snackbar(
            'สำเร็จ',
            'สร้างรายการ "${_nameController.text}" เรียบร้อยแล้ว',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
          
          // กลับไปหน้า Home พร้อมส่งสัญญาณว่าสร้างสำเร็จ
          Navigator.pop(context, true);
        }
      } else if (res.statusCode == 401) {
        debugPrint("Unauthorized - Token expired");
        if (mounted) {
          Get.snackbar(
            'ข้อผิดพลาด',
            'กรุณาเข้าสู่ระบบใหม่',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          Get.offAllNamed('/login');
        }
      } else {
        String errorMessage;
        try {
          final data = jsonDecode(res.body);
          errorMessage =
              data["message"] ?? "เกิดข้อผิดพลาด (${res.statusCode})";
        } catch (e) {
          errorMessage =
              "เกิดข้อผิดพลาด: ${res.statusCode} - ${res.reasonPhrase}";
        }

        debugPrint("API Error: $errorMessage");
        if (mounted) {
          Get.snackbar(
            'ข้อผิดพลาด',
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint("Exception occurred: $e");
      if (mounted) {
        Get.snackbar(
          'ข้อผิดพลาด',
          "เกิดข้อผิดพลาด: ${e.toString()}",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มรายการธุรกรรม"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: !_storageInitialized
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('กำลังเริ่มต้นระบบ...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ข้อมูลรายการ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: "ชื่อรายการ *",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.title),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty
                                  ? "กรุณาใส่ชื่อรายการ"
                                  : null,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _descController,
                              decoration: const InputDecoration(
                                labelText: "รายละเอียด",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "จำนวนเงิน *",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                                suffixText: '฿',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "กรุณาใส่จำนวนเงิน";
                                }
                                if (int.tryParse(val.trim()) == null) {
                                  return "จำนวนเงินไม่ถูกต้อง";
                                }
                                if (int.parse(val.trim()) <= 0) {
                                  return "จำนวนเงินต้องมากกว่า 0";
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            DropdownButtonFormField<int>(
                              value: _type,
                              decoration: const InputDecoration(
                                labelText: "ประเภทรายการ",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_upward, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text("รายรับ"),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: -1,
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_downward, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text("รายจ่าย"),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() => _type = val!);
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            InkWell(
                              onTap: _pickDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: "วันที่",
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _createTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text("กำลังบันทึก..."),
                                ],
                              )
                            : const Text(
                                "บันทึกรายการ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const Text(
                      '* ช่องที่ต้องกรอก',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}