import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SimulationPage extends StatefulWidget {
  const SimulationPage({super.key});

  @override
  State<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends State<SimulationPage> {
  double _revenueChange = 0.0;
  double _expenseChange = 0.0;
  double _interestRateShift = 0.0;
  double _currencyShock = 0.0;
  
  List<Map<String, dynamic>> _results = [];
  String _projectedBreachDate = "NO BREACH PROJECTED";

  void _runSimulation() {
    setState(() {
      // Combined stress factor
      double stress = _revenueChange - _expenseChange - (_interestRateShift * 0.5) - (_currencyShock * 0.2);
      
      _results = [
        {
          "name": "Debt-to-EBITDA", 
          "status": stress < -0.15 ? "Breach" : (stress < -0.05 ? "Warning" : "Compliant"), 
          "value": 3.2 * (1 - stress)
        },
        {
          "name": "Interest Coverage", 
          "status": stress < -0.2 ? "Breach" : (stress < -0.1 ? "Warning" : "Compliant"), 
          "value": 2.5 * (1 + stress)
        },
      ];

      if (stress < -0.1) {
        _projectedBreachDate = "MARCH 15, 2026";
      } else {
        _projectedBreachDate = "NO BREACH PROJECTED";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Controls
          Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.blueGrey, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stress Parameters', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildSlider('Revenue Change', _revenueChange, (v) => setState(() => _revenueChange = v)),
                _buildSlider('Expense Shift', _expenseChange, (v) => setState(() => _expenseChange = v)),
                _buildSlider('Interest Rate Shift', _interestRateShift, (v) => setState(() => _interestRateShift = v)),
                _buildSlider('Currency Shock', _currencyShock, (v) => setState(() => _currencyShock = v)),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _runSimulation,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                    child: const Text('Calculate Projection'),
                  ),
                ),
              ],
            ),
          ),
          // Output
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreachTimeline(),
                  const SizedBox(height: 32),
                  Text('Simulated Covenant Outcomes', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._results.map((r) => _buildSimResultCard(r)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              Text('${(val * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: val, min: -0.5, max: 0.5, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildBreachTimeline() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BREACH TIMELINE PREDICTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Text(_projectedBreachDate, style: TextStyle(color: _projectedBreachDate.contains('NO') ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green, Colors.amber, Colors.red],
                stops: const [0.0, 0.6, 0.8, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('NOW', style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
              Text('Q1 2026', style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
              Text('Q2 2026', style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
              Text('Q3 2026', style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimResultCard(Map<String, dynamic> r) {
    Color color = r['status'] == 'Compliant' ? Colors.green : (r['status'] == 'Warning' ? Colors.amber : Colors.red);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.analytics, color: color),
        title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Projected Ratio: ${r['value'].toStringAsFixed(2)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
          child: Text(r['status'], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}
