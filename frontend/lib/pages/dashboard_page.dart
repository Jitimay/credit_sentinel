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
  // Mock data for initial UI
  final List<Map<String, dynamic>> covenants = [
    {"name": "Debt-to-EBITDA", "status": "Compliant", "value": 3.2, "threshold": 3.5},
    {"name": "Interest Coverage", "status": "Warning", "value": 2.1, "threshold": 2.0},
    {"name": "Current Ratio", "status": "Breach", "value": 0.9, "threshold": 1.2},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildStatsOverview(),
                  const SizedBox(height: 32),
                  _buildMainDashboard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.security, color: Color(0xFF1E88E5), size: 32),
                const SizedBox(width: 12),
                Text(
                  'Sentinel',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(Icons.dashboard, 'Dashboard', active: true),
          _buildSidebarItem(Icons.upload_file, 'Ingestion', onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadPage()));
          }),
          _buildSidebarItem(Icons.analytics, 'Risk Analysis', onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const SimulationPage()));
          }),
          _buildSidebarItem(Icons.history, 'Audit Logs', onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const AuditLogPage()));
          }),
          const Spacer(),
          _buildSidebarItem(Icons.settings, 'Settings'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, {bool active = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E88E5).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? const Color(0xFF1E88E5) : Colors.blueGrey),
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.blueGrey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Covenant Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Monitoring 12 active loan covenants for Acme Corp.',
              style: TextStyle(color: Colors.blueGrey[400]),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UploadPage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New Analysis'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        _buildStatCard('Total Covenants', '12', Icons.list_alt, Colors.blue),
        const SizedBox(width: 24),
        _buildStatCard('Active Breaches', '1', Icons.warning_rounded, Colors.red),
        const SizedBox(width: 24),
        _buildStatCard('Early Warnings', '2', Icons.info_outline, Colors.amber),
        const SizedBox(width: 24),
        _buildStatCard('Avg Risk Score', '72%', Icons.speed, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 16),
              Text(value, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Covenant List
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Monitoring',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...covenants.map((c) => CovenantCard(data: c)).toList(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Trend Analysis
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend Analysis',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Debt-to-EBITDA History', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  const FlSpot(0, 3.0),
                                  const FlSpot(1, 3.1),
                                  const FlSpot(2, 3.3),
                                  const FlSpot(3, 3.2),
                                ],
                                isCurved: true,
                                color: const Color(0xFF1E88E5),
                                barWidth: 4,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
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
}
