import 'package:flutter/material.dart';
import 'edit_transaction.dart'; // import หน้าแก้ไข

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

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

  // ฟังก์ชันไปหน้า Edit
  void _navigateToEditScreen() async {
    final updatedTransaction = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(transaction: widget.transaction),
      ),
    );

    if (updatedTransaction != null) {
      setState(() {
        widget.transaction['name'] = updatedTransaction['name'];
        widget.transaction['desc'] = updatedTransaction['desc'];
        widget.transaction['amount'] = updatedTransaction['amount'];
        widget.transaction['type'] = updatedTransaction['type'];
        widget.transaction['date'] = updatedTransaction['date'];
      });

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction['type'] == 1;
    final amount = (widget.transaction['amount'] ?? 0).toDouble();

    return WillPopScope(
      onWillPop: () async {
        // ส่งสัญญาณกลับ Home ว่ามีการแก้ไข
        Navigator.pop(context, 'edited');
        return false;
      },
      child: Scaffold(
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
                // Header
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
                      // ปุ่ม Back
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context, 'edited'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.transaction['name'] ?? 'รายละเอียดธุรกรรม',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                    ],
                  ),
                ),
                // รายละเอียด
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
                                          color: (isIncome ? Colors.green : Colors.red)
                                              .withOpacity(0.4),
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
                                                  isIncome
                                                      ? Icons.trending_up
                                                      : Icons.trending_down,
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
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            content,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: contentColor ?? Colors.black87),
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
