import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_validate/services/universal_storage.dart'; // เปลี่ยนจาก storage_service.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../controllers/trans_controller.dart';

class CreateTransactionPage extends StatefulWidget {
  // ลบ token parameter ออกเพราะจะดึงจาก UniversalStorageService
  const CreateTransactionPage({super.key});

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionPageState();
}

class _CreateTransactionPageState extends State<CreateTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final transactionController = Get.find<TransactionController>();
  int _type = -1; // -1 = expense, 1 = income
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initStorageService();
  }

  Future<void> _initStorageService() async {
    try {
      // ใช้ UniversalStorageService แทน StorageService
      await UniversalStorageService.init();
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

    setState(() => _loading = true);

    try {
      // ใช้ UniversalStorageService แบบ static method
      final token = UniversalStorageService.getToken();

      // ตรวจสอบ token
      if (token == null || token.isEmpty) {
        debugPrint("Token is null or empty");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("กรุณาเข้าสู่ระบบใหม่")),
          );
          Get.offAllNamed('/login');
        }
        return;
      }

      final url = Uri.parse(
        "https://transactions-cs.vercel.app/api/transaction",
      );
      await transactionController.refreshData();
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
        
        // เพิ่มการบันทึก transaction ลง local storage (ถ้าต้องการ)
        try {
          final transactionData = {
            "uuid": DateTime.now().millisecondsSinceEpoch.toString(), // สร้าง uuid ชั่วคราว
            "wallet": "default",
            "name": _nameController.text.trim(),
            "desc": _descController.text.trim(),
            "amount": int.tryParse(_amountController.text) ?? 0,
            "type": _type,
            "date": _selectedDate.toIso8601String(),
            "createdAt": DateTime.now().toIso8601String(),
            "updatedAt": DateTime.now().toIso8601String(),
          };
          
          await UniversalStorageService.addTransaction(transactionData);
          debugPrint("Transaction saved to local storage");
        } catch (e) {
          debugPrint("Failed to save transaction to local storage: $e");
        }
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text("สร้างรายการสำเร็จ"),
                content: Text(
                  "รายการ \"${_nameController.text}\" ถูกสร้างเรียบร้อยแล้ว",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // ปิด popup
                      _clearForm();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
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
          errorMessage = data["message"] ?? "เกิดข้อผิดพลาด (${res.statusCode})";
        } catch (e) {
          errorMessage = "เกิดข้อผิดพลาด: ${res.statusCode} - ${res.reasonPhrase}";
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

  void _clearForm() {
    _nameController.clear();
    _descController.clear();
    _amountController.clear();
    setState(() {
      _type = -1;
      _selectedDate = DateTime.now();
    });
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
      appBar: AppBar(title: const Text("สร้างรายการธุรกรรม")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "ชื่อรายการ",
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? "กรุณากรอกชื่อรายการ"
                    : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "รายละเอียด",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "จำนวนเงิน",
                  border: OutlineInputBorder(),
                  suffixText: "บาท",
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "กรุณากรอกจำนวนเงิน";
                  if (int.tryParse(val) == null) return "จำนวนเงินไม่ถูกต้อง";
                  if (int.parse(val) <= 0) return "จำนวนเงินต้องมากกว่า 0";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<int>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: "ประเภทรายการ",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text("รายรับ")),
                  DropdownMenuItem(value: -1, child: Text("รายจ่าย")),
                ],
                onChanged: (val) {
                  setState(() => _type = val!);
                },
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "วันที่",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text("เลือกวันที่"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 1 ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _type == 1 ? "บันทึกรายรับ" : "บันทึกรายจ่าย",
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}