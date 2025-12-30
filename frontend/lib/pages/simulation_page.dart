import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  double _ebitdaChange = 0.0;
  double _debtChange = 0.0;
  List<Map<String, dynamic>> _results = [];

  void _runSimulation() {
    // Simulated local logic for demo (normally calls /simulate)
    setState(() {
      _results = [
        {"name": "Debt-to-EBITDA", "status": _ebitdaChange < -0.2 ? "Breach" : "Compliant", "value": (3.2 * (1 + _debtChange)) / (1 + _ebitdaChange)},
        {"name": "Interest Coverage", "status": _ebitdaChange < -0.1 ? "Warning" : "Compliant", "value": 2.5 * (1 + _ebitdaChange)},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Financial Stress Simulation', style: GoogleFonts.outfit())),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('Adjust Parameters', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Text('EBITDA Change: ${(_ebitdaChange * 100).round()}%'),
                    Slider(
                      value: _ebitdaChange,
                      min: -0.5,
                      max: 0.5,
                      onChanged: (v) => setState(() => _ebitdaChange = v),
                    ),
                    const SizedBox(height: 16),
                    Text('Total Debt Change: ${(_debtChange * 100).round()}%'),
                    Slider(
                      value: _debtChange,
                      min: -0.5,
                      max: 0.5,
                      onChanged: (v) => setState(() => _debtChange = v),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _runSimulation, child: const Text('Run What-If Analysis')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: _getStatusColor(r['status'])),
                        title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Simulated Value: ${r['value'].toStringAsFixed(2)}'),
                        trailing: Text(r['status'], style: TextStyle(color: _getStatusColor(r['status']), fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'Breach') return Colors.red;
    if (status == 'Warning') return Colors.amber;
    return Colors.green;
  }
}
