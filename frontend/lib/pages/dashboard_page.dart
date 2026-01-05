import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/covenant_card.dart';
import 'upload_page.dart';
import 'simulation_page.dart';
import 'audit_log_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let AppShell handle it
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEngagementRow(),
            const SizedBox(height: 32),
            _buildHighlightsGrid(),
            const SizedBox(height: 32),
            _buildCovenantListAndAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementRow() {
    return Row(
      children: [
        _buildHealthScoreGauge(),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Acme Corp Loan Health', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Calculated based on 12 active covenants and Q3 financials.', style: TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 16),
              Row(
                children: [
                   _buildQuickAction(Icons.upload_file, 'Update Data'),
                   const SizedBox(width: 12),
                   _buildQuickAction(Icons.summarize, 'Gen Report'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoreGauge() {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber, width: 4),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('72', style: GoogleFonts.outfit(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.amber)),
            const Text('HEALTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightsGrid() {
    return Row(
      children: [
        _buildHighlightCard('9', 'COVENANTS OK', Colors.green, Icons.check_circle_outline),
        const SizedBox(width: 20),
        _buildHighlightCard('2', 'WARNINGS', Colors.amber, Icons.error_outline),
        const SizedBox(width: 20),
        _buildHighlightCard('1', 'BREACHES', Colors.red, Icons.cancel_outlined),
        const SizedBox(width: 20),
        _buildHighlightCard('42', 'DAYS TO REVIEW', Colors.blue, Icons.update),
      ],
    );
  }

  Widget _buildHighlightCard(String val, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(val, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCovenantListAndAlerts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Covenant Monitor', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const CovenantCard(data: {"name": "Debt-to-EBITDA", "status": "Compliant", "value": 3.2, "threshold": 3.5}),
              const CovenantCard(data: {"name": "Interest Coverage", "status": "Warning", "value": 2.1, "threshold": 2.0}),
              const CovenantCard(data: {"name": "Current Ratio", "status": "Breach", "value": 0.9, "threshold": 1.2}),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latest Alerts', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildAlertItem('Current Ratio Breach!', 'Acme Corp dropped to 0.9x', Colors.red),
              _buildAlertItem('Interest Coverage Warning', 'Approaching 2.0x limit', Colors.amber),
              _buildAlertItem('New PDF Parsed', '12 covenants extracted', Colors.blue),
              const SizedBox(height: 32),
              Text('Risk Score History', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                height: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(0, 85),
                          const FlSpot(1, 80),
                          const FlSpot(2, 72),
                          const FlSpot(3, 75),
                        ],
                        isCurved: true,
                        color: Colors.amber,
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.amber.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(String title, String sub, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(sub, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
