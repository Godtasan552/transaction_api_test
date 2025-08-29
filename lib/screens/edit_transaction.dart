import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../controllers/trans_controller.dart';
import '../utils/navigation_helper.dart';
import 'package:uuid/uuid.dart';


class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditTransactionPage({super.key, required this.transaction});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;

  late TransactionController _controller;

  // เก็บ type: 1 = รายรับ, -1 = รายจ่าย
  int _selectedType = 1;
  List<bool> _typeSelected = [true, false]; // [รายรับ, รายจ่าย]

  @override
  void initState() {
    super.initState();

    // หา controller จาก Get ถ้ามี ถ้าไม่มี fallback เป็น instance ใหม่
    try {
      _controller = Get.find<TransactionController>();
    } catch (e) {
      _controller = TransactionController();
    }

    _titleController = TextEditingController(text: widget.transaction['name']);
    _amountController = TextEditingController(
      text: widget.transaction['amount'].toString(),
    );

    // date
    final rawDate = widget.transaction['date'];
    if (rawDate is DateTime) {
      _selectedDate = rawDate;
    } else if (rawDate is String) {
      try {
        _selectedDate = DateTime.parse(rawDate);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }

    // type (safely parse)
    final rawType = widget.transaction['type'];
    if (rawType is int) {
      _selectedType = rawType;
    } else if (rawType is String) {
      final parsed = int.tryParse(rawType);
      if (parsed != null) _selectedType = parsed;
    }
    // update UI selection array
    _typeSelected = [_selectedType == 1, _selectedType == -1];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    // สร้าง Transaction object โดยใช้ type ที่เลือก
    final updatedTransaction = Transaction(
      uuid: widget.transaction['uuid'],
      wallet: widget.transaction['wallet'] ?? 'default',
      name: _titleController.text,
      desc: widget.transaction['desc'],
      amount: double.parse(_amountController.text),
      type: _selectedType,
      date: _selectedDate,
      createdAt: widget.transaction['createdAt'] != null
          ? DateTime.parse(widget.transaction['createdAt'])
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await _controller.editTransactionAPI(updatedTransaction);

    if (success) {
      Navigator.pop(context, updatedTransaction.toJson());
    } else {
      NavigationHelper.showErrorSnackBar("ไม่สามารถแก้ไขธุรกรรมได้");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("แก้ไขรายการธุรกรรม"),
        backgroundColor: Colors.teal,
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // ชื่อรายการ
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "ชื่อรายการ",
                      prefixIcon: const Icon(Icons.edit, color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? "กรุณากรอกชื่อรายการ"
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // จำนวนเงิน
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: "จำนวนเงิน",
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "กรุณากรอกจำนวนเงิน";
                      if (double.tryParse(value) == null) {
                        return "กรุณากรอกตัวเลขที่ถูกต้อง";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // เลือกประเภท (type)
                  Row(
                    children: [
                      const Text("ประเภท: "),
                      const SizedBox(width: 12),
                      ToggleButtons(
                        isSelected: _typeSelected,
                        onPressed: (index) {
                          setState(() {
                            _selectedType = (index == 0)
                                ? 1
                                : -1; // เก็บค่าประเภท
                            _typeSelected = [
                              index == 0,
                              index == 1,
                            ]; // อัพเดตปุ่ม Toggle
                          });
                        },

                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(
                          minHeight: 36,
                          minWidth: 100,
                        ),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('รายรับ'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('รายจ่าย'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // วันที่
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal, width: 1.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "วันที่: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Icon(Icons.edit_calendar, color: Colors.teal),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ปุ่มบันทึก
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "บันทึกการแก้ไข",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
