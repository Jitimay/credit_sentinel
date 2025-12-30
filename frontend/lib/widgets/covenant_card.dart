import 'package:flutter/material.dart';

class CovenantCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CovenantCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String status = data['status'];
    final Color statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Threshold: ${data['threshold']}',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data['value'].toString(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20, color: Colors.blueGrey),
              onPressed: () {
                _showExplanation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExplanation(BuildContext context) {
    final String explanation = data['explanation'] ?? 
        "The ${data['name']} ratio is calculated as ${data['value']}. ${data['status'] == 'Compliant' ? 'This is within the required legal limits.' : 'This exceeds the maximum threshold of ${data['threshold']} defined in the loan agreement.'}";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${data['name']} - Explainable Analysis', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(explanation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Compliant':
        return Colors.green;
      case 'Warning':
        return Colors.amber;
      case 'Breach':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
