import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:form_validate/utils/api.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'edit_transaction.dart';
import '../services/universal_storage.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function(Map<String, dynamic>)? onEdit;
  final Function(String)? onDelete; // เพิ่ม callback สำหรับการลบ

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete, // รับ onDelete เข้ามาใน constructor
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับแสดง Dialog ยืนยันการลบ
  Future<void> _showDeleteConfirmationDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // ป้องกันการปิด dialog โดยการแตะด้านนอก
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'ยืนยันการลบ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'คุณต้องการลบรายการธุรกรรมนี้หรือไม่?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.transaction['name'] ?? 'ไม่ระบุชื่อ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'จำนวน: ${(widget.transaction['type'] == 1 ? '+' : '-')}฿${(widget.transaction['amount'] ?? 0).toDouble().toStringAsFixed(2)}',
                      style: TextStyle(
                        color: widget.transaction['type'] == 1 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.transaction['date'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'วันที่: ${widget.transaction['date']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'การดำเนินการนี้ไม่สามารถยกเลิกได้',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ลบ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteTransaction();
    }
  }

  // ฟังก์ชันลบธุรกรรมผ่าน API
  Future<void> _deleteTransaction() async {
    try {
      // แสดง loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังลบรายการ...'),
                  ],
                ),
              ),
            ),
          );
        },
      );

      await UniversalStorageService.init();
      final token = UniversalStorageService.getToken();

      if (token == null || token.isEmpty) {
        Navigator.of(context).pop(); // ปิด loading dialog
        _showErrorSnackBar('กรุณาเข้าสู่ระบบใหม่');
        return;
      }

      // สร้าง URL สำหรับลบธุรกรรม (ใช้ uuid หรือ id ของธุรกรรม)
      final transactionId = widget.transaction['uuid'] ?? widget.transaction['id'];
      if (transactionId == null) {
        Navigator.of(context).pop(); // ปิด loading dialog
        _showErrorSnackBar('ไม่พบรหัสธุรกรรม');
        return;
      }

      // แก้ไข URL ให้เรียบร้อย
      final url = Uri.parse('$BASE_URL$DELETE_TRANSACTION_ENDPOINT$transactionId');


      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('การลบใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
        },
      );

      Navigator.of(context).pop(); // ปิด loading dialog

      if (response.statusCode == 200 || response.statusCode == 204) {
        // ลบสำเร็จ
        _showSuccessSnackBar('ลบรายการสำเร็จ');
        
        // เรียก callback ถ้ามี
        if (widget.onDelete != null) {
          widget.onDelete!(transactionId.toString());
        }
        
        // กลับไปหน้า home พร้อมส่งสัญญาณว่ามีการลบ
        Navigator.of(context).pop('deleted');
        
      } else if (response.statusCode == 401) {
        _showErrorSnackBar('กรุณาเข้าสู่ระบบใหม่');
      } else if (response.statusCode == 404) {
        _showErrorSnackBar('ไม่พบรายการที่ต้องการลบ');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'เกิดข้อผิดพลาดในการลบรายการ';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      Navigator.of(context).pop(); // ปิด loading dialog ในกรณีเกิด error
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  // ฟังก์ชันแสดง Success SnackBar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ฟังก์ชันแสดง Error SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ฟังก์ชันนำทางไปหน้าแก้ไข
  void _navigateToEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => edit_transaction_page(transaction: widget.transaction),
      ),
    );

    if (result == 'edited') {
      if (widget.onEdit != null) {
        // await widget.onEdit!(editedTransactionData);
      }
      _showSuccessSnackBar('แก้ไขรายการเรียบร้อยแล้ว');
      Navigator.pop(context, 'edited'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction['type'] == 1;
    final amount = (widget.transaction['amount'] ?? 0).toDouble();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isIncome
                ? [Colors.green.shade50, Colors.green.shade100, Colors.white]
                : [Colors.red.shade50, Colors.red.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIncome
                        ? [Colors.green.shade600, Colors.green.shade400]
                        : [Colors.red.shade600, Colors.red.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isIncome ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.transaction['name'] ?? 'รายละเอียดธุรกรรม',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // ปุ่ม Edit
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _navigateToEditScreen,
                        tooltip: 'แก้ไข',
                      ),
                    ),
                    // ปุ่ม Delete (ใหม่)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: _showDeleteConfirmationDialog,
                        tooltip: 'ลบรายการ',
                      ),
                    ),
                  ],
                ),
              ),
              // ส่วนรายละเอียดธุรกรรมยังคงเหมือนเดิม
              Expanded(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isIncome
                                          ? [Colors.green.shade600, Colors.green.shade400]
                                          : [Colors.red.shade600, Colors.red.shade400],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isIncome ? Colors.green : Colors.red).withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: 1.0 + (_pulseController.value * 0.1),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isIncome ? Icons.trending_up : Icons.trending_down,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        isIncome ? 'รายรับ' : 'รายจ่าย',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${isIncome ? '+' : '-'}฿${amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildDetailCard(
                                icon: Icons.receipt_long,
                                title: 'ชื่อรายการ',
                                content: widget.transaction['name'] ?? 'ไม่ระบุชื่อ',
                                delay: 200,
                              ),
                              if (widget.transaction['desc'] != null &&
                                  widget.transaction['desc'].toString().isNotEmpty)
                                _buildDetailCard(
                                  icon: Icons.description,
                                  title: 'รายละเอียด',
                                  content: widget.transaction['desc'],
                                  delay: 300,
                                ),
                              _buildDetailCard(
                                icon: Icons.calendar_today,
                                title: 'วันที่',
                                content: widget.transaction['date'] ?? '',
                                delay: 400,
                              ),
                              _buildDetailCard(
                                icon: Icons.category,
                                title: 'ประเภท',
                                content: isIncome ? 'รายรับ' : 'รายจ่าย',
                                delay: 500,
                                contentColor: isIncome ? Colors.green : Colors.red,
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.blue.shade600, Colors.blue.shade400],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                                        label: const Text(
                                          'กลับหน้าแรก',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required int delay,
    Color? contentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 800 + delay),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Opacity(
              opacity: value,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.blue.shade600, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            content,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: contentColor ?? Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}