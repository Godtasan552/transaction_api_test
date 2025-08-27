import 'package:flutter/material.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction['type'] == 1;
    final amount = (transaction['amount'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(transaction['name'] ?? 'รายละเอียดธุรกรรม'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ชื่อรายการ: ${transaction['name']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (transaction['desc'] != null && transaction['desc'].toString().isNotEmpty)
              Text('รายละเอียด: ${transaction['desc']}'),
            const SizedBox(height: 8),
            Text('วันที่: ${transaction['date'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'จำนวนเงิน: ${isIncome ? '+' : '-'}฿${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text('ประเภท: ${isIncome ? 'รายรับ' : 'รายจ่าย'}'),
          ],
        ),
      ),
    );
  }
}
