import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const CreditSentinelApp());
}

class CreditSentinelApp extends StatelessWidget {
  const CreditSentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreditSentinel™',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), 
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Initializing...';
  List<dynamic> _loans = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  Future<void> _checkHealth() async {
    try {
      final response = await http.get(Uri.parse('/api/health'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = 'Backend: ${data['status']} (${data['platform']})';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Backend: Offline';
      });
    }
  }

  Future<void> _createDemoData() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(Uri.parse('/api/demo-data'));
      if (response.statusCode == 200) {
        await _loadLoans();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data created successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _loading = false);
  }

  Future<void> _loadLoans() async {
    try {
      final response = await http.get(Uri.parse('/api/loans'));
      if (response.statusCode == 200) {
        setState(() {
          _loans = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading loans: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF1E88E5)),
            const SizedBox(width: 8),
            Text(
              'CreditSentinel™',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Powered Loan Covenant Monitoring',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: $_status',
                      style: TextStyle(
                        color: _status.contains('healthy') ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _createDemoData,
                          icon: _loading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                          label: const Text('Create Demo Data'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _loadLoans,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Loans'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Active Loans (${_loans.length})',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loans.isEmpty
                ? const Center(
                    child: Text(
                      'No loans found. Create demo data to get started.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _loans.length,
                    itemBuilder: (context, index) {
                      final loan = _loans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.account_balance, color: Color(0xFF1E88E5)),
                          title: Text(loan['borrower_name'] ?? 'Unknown'),
                          subtitle: Text('\$${(loan['loan_amount'] ?? 0).toStringAsFixed(0)}'),
                          trailing: Chip(
                            label: Text(loan['status'] ?? 'Unknown'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
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
}
