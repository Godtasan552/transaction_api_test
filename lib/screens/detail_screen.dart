import 'package:flutter/material.dart';
import 'edit_transaction.dart'; // อย่าลืม import ไฟล์ edit_transaction_page.dart

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final Function(Map<String, dynamic>)? onDelete; // callback สำหรับลบข้อมูล
  final Function(Map<String, dynamic>)? onEdit; // เพิ่ม callback สำหรับแก้ไขข้อมูล

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onEdit, // รับ onEdit เข้ามาใน constructor
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600, size: 28),
              const SizedBox(width: 12),
              const Text(
                'ยืนยันการลบ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          content: Text(
            'คุณต้องการลบรายการ "${widget.transaction['name'] ?? 'ไม่ระบุชื่อ'}" หรือไม่?\n\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red.shade600, Colors.red.shade400]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(context); // ปิด dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  try {
                    if (widget.onDelete != null) await widget.onDelete!(widget.transaction);
                    Navigator.pop(context); // ปิด loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('ลบรายการ "${widget.transaction['name']}" เรียบร้อยแล้ว'),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    Navigator.pop(context, 'deleted');
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.error, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(child: Text('เกิดข้อผิดพลาดในการลบข้อมูล กรุณาลองใหม่อีกครั้ง')),
                          ],
                        ),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: const Text(
                  'ลบ',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // สร้าง method ใหม่สำหรับนำทางไปยังหน้าแก้ไข
  void _navigateToEditScreen() async {
    // ใช้ Navigator.push เพื่อนำทางไปยัง edit_transaction_page
    // และส่งข้อมูล transaction ไปด้วย
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => edit_transaction_page(transaction: widget.transaction),
      ),
    );

    // หากมีการแก้ไขและบันทึกข้อมูลสำเร็จ (result เป็น 'edited')
    if (result == 'edited') {
      // สามารถเรียก callback หรือฟังก์ชันที่ต้องการได้ เช่น การอัปเดตข้อมูลบนหน้าจอหลัก
      if (widget.onEdit != null) {
        // อาจจะต้องส่งข้อมูลที่แก้ไขแล้วกลับมาด้วย
        // ตัวอย่างเช่น await widget.onEdit!(editedTransactionData);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('แก้ไขรายการเรียบร้อยแล้ว'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      // pop หน้าจอ TransactionDetailScreen ออกไป
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
                    // ปุ่ม Delete
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: _showDeleteDialog,
                        tooltip: 'ลบ',
                      ),
                    ),
                  ],
                ),
              ),
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