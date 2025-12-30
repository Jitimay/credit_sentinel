import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> logs = [
      {"time": "2025-12-30 16:40:00", "event": "What-if simulation run (EBITDA: -10%)", "user": "josh_admin"},
      {"time": "2025-12-30 16:35:00", "event": "Financial statement analysis complete", "user": "System"},
      {"time": "2025-12-30 16:30:00", "event": "Covenant extraction from Acme_Loan_v2.pdf", "user": "josh_admin"},
      {"time": "2025-12-30 10:00:00", "event": "System initialized", "user": "System"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Audit Trail & Logs', style: GoogleFonts.outfit())),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: logs.length,
        itemBuilder: (context, i) {
          final log = logs[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: Colors.blueGrey),
              title: Text(log['event']!),
              subtitle: Text('${log['time']} • User: ${log['user']}'),
            ),
          );
        },
      ),
    );
  }
}
