import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? _agreementPath;
  String? _financialsPath;
  bool _isProcessing = false;

  Future<void> _pickAgreement() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );

    if (result != null) {
      setState(() {
        _agreementPath = result.files.single.name;
      });
    }
  }

  Future<void> _pickFinancials() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );

    if (result != null) {
      setState(() {
        _financialsPath = result.files.single.name;
      });
    }
  }

  void _startAnalysis() {
    setState(() {
      _isProcessing = true;
    });
    // Simulate processing delay
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis Complete! Dashboard updated.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ingestion Engine', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUploadSection(
                title: 'Loan Agreement',
                subtitle: 'Upload the legal contract (PDF/TXT)',
                path: _agreementPath,
                icon: Icons.description,
                onTap: _pickAgreement,
              ),
              const SizedBox(height: 32),
              _buildUploadSection(
                title: 'Financial Statements',
                subtitle: 'Upload borrower data (XLSX/CSV)',
                path: _financialsPath,
                icon: Icons.table_chart,
                onTap: _pickFinancials,
              ),
              const SizedBox(height: 48),
              if (_isProcessing)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI is extracting covenants and analyzing risks...'),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: (_agreementPath != null && _financialsPath != null) ? _startAnalysis : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start AI Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection({
    required String title,
    required String subtitle,
    String? path,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: path != null ? const Color(0xFF1E88E5) : Colors.blueGrey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: path != null ? const Color(0xFF1E88E5) : Colors.blueGrey),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.blueGrey)),
            if (path != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(path, style: const TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
