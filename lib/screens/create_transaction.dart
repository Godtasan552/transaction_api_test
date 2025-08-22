import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_validate/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CreateTransactionPage extends StatefulWidget {
  // เอา token parameter ออก เพราะจะดึงจาก StorageService เอง
  const CreateTransactionPage({super.key, required String token});

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

  // เพิ่มตัวแปรสำหรับ StorageService
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _initStorageService();
  }

  Future<void> _initStorageService() async {
    try {
      _storageService = StorageService();
      await _storageService.init();
      debugPrint("StorageService initialized successfully");
    } catch (e) {
      debugPrint("Failed to initialize StorageService: $e");
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
      // ใช้ StorageService ที่ init แล้ว
      final token = _storageService.getToken();

      // ตรวจสอบ token
      if (token == null || token.isEmpty) {
        debugPrint("Token is null or empty");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("กรุณาเข้าสู่ระบบใหม่")));
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
          showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text("created successfully"),
                content: Text(
                  "Transaction \"${_nameController.text}\" successfully",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // ปิด popup
                      _nameController.clear();
                      _descController.clear();
                      _amountController.clear();
                      setState(() {
                        _type = -1;
                        _selectedDate = DateTime.now();
                      });
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
      appBar: AppBar(title: const Text("Create Transaction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name Transaction",
                ),
                validator: (val) => val == null || val.isEmpty
                    ? "Enter name transaction"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Detail"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
                validator: (val) {
                  if (val == null || val.isEmpty) return "please enter amount";
                  if (int.tryParse(val) == null) return "จำนวนเงินไม่ถูกต้อง";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: "Type transaction",
                ),
                items: const [
                  DropdownMenuItem(value: -1, child: Text("Income")),
                  DropdownMenuItem(value: 1, child: Text("Expenses")),
                ],
                onChanged: (val) {
                  setState(() => _type = val!);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Date: ${_selectedDate.toLocal()}".split(' ')[0],
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text("Select date"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _createTransaction,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
