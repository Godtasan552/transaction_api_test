import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateTransactionPage extends StatefulWidget {
  final String token; // รับ JWT token จากหน้าก่อน
  const CreateTransactionPage({super.key, required this.token});

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

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final url = Uri.parse("https://transactions-cs.vercel.app/api/transaction"); // เปลี่ยนเป็น endpoint จริง
    final body = {
      "name": _nameController.text,
      "desc": _descController.text,
      "amount": int.tryParse(_amountController.text) ?? 0,
      "type": _type,
      "date": _selectedDate.toIso8601String().split("T")[0], // "YYYY-MM-DD"
    };

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction created successfully")),
        );
        Navigator.pop(context, true); // ส่ง true กลับไปว่ามีการเพิ่มแล้ว
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data["message"]}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("สร้างธุรกรรมใหม่")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "ชื่อธุรกรรม"),
                validator: (val) =>
                    val == null || val.isEmpty ? "กรุณากรอกชื่อธุรกรรม" : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "รายละเอียด"),
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "จำนวนเงิน"),
                validator: (val) {
                  if (val == null || val.isEmpty) return "กรุณากรอกจำนวนเงิน";
                  if (int.tryParse(val) == null) return "จำนวนเงินไม่ถูกต้อง";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _type,
                decoration: const InputDecoration(labelText: "ประเภทธุรกรรม"),
                items: const [
                  DropdownMenuItem(value: -1, child: Text("รายจ่าย")),
                  DropdownMenuItem(value: 1, child: Text("รายรับ")),
                ],
                onChanged: (val) {
                  setState(() => _type = val!);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text("วันที่: ${_selectedDate.toLocal()}".split(' ')[0]),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text("เลือกวันที่"),
                  )
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _createTransaction,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("บันทึก"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

