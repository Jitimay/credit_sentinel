import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  int? _selectedCovenantIndex;

  final List<Map<String, dynamic>> _extractedCovenants = [
    {"name": "Net Debt / EBITDA", "threshold": "3.5x", "type": "Financial", "status": "Compliant", "clause": "Section 4.1(a)"},
    {"name": "Interest Coverage", "threshold": "> 2.0x", "type": "Financial", "status": "Warning", "clause": "Section 4.1(b)"},
    {"name": "Current Ratio", "threshold": "> 1.2x", "type": "Financial", "status": "Breach", "clause": "Section 4.3"},
    {"name": "Quarterly Financials", "threshold": "45 Days", "type": "Reporting", "status": "Compliant", "clause": "Section 5.1"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Left Panel: PDF Viewer (Simulated)
          Expanded(
            flex: 3,
            child: _buildPdfViewer(),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Colors.blueGrey),
          // Right Panel: Extraction Table
          Expanded(
            flex: 2,
            child: _buildExtractionPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Container(
      color: const Color(0xFF1E293B).withOpacity(0.5),
      child: Column(
        children: [
          _buildPdfToolbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Card(
                elevation: 8,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Text('LOAN AGREEMENT', style: GoogleFonts.merriweather(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 48),
                      _buildPdfPlaceholderText('Section 4. FINANCIAL COVENANTS', isHeader: true),
                      _buildPdfPlaceholderText('4.1 The Borrower shall maintain at all times:'),
                      _buildPdfHighlightedText('(a) a ratio of Net Debt to EBITDA not exceeding 3.5:1.0;', isHighlighted: _selectedCovenantIndex == 0),
                      _buildPdfHighlightedText('(b) an Interest Coverage Ratio of not less than 2.0:1.0;', isHighlighted: _selectedCovenantIndex == 1),
                      const SizedBox(height: 24),
                      _buildPdfPlaceholderText('Section 5. REPORTING COVENANTS', isHeader: true),
                      _buildPdfHighlightedText('5.1 The Borrower shall deliver Quarterly Financials within 45 days of period end.', isHighlighted: _selectedCovenantIndex == 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfToolbar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFF0F172A),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          const Text('Acme_Senior_Loan_v2.pdf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.zoom_in, size: 18),
          const SizedBox(width: 16),
          const Icon(Icons.zoom_out, size: 18),
          const SizedBox(width: 16),
          const Icon(Icons.print_outlined, size: 18),
        ],
      ),
    );
  }

  Widget _buildPdfPlaceholderText(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.merriweather(
          color: Colors.black87,
          fontSize: isHeader ? 16 : 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPdfHighlightedText(String text, {bool isHighlighted = false}) {
    return InkWell(
      onTap: () {},
      child: Container(
        color: isHighlighted ? Colors.yellow.withOpacity(0.3) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: GoogleFonts.merriweather(
            color: Colors.black,
            fontSize: 13,
            decoration: isHighlighted ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Widget _buildExtractionPanel() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Extracted Covenants', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const Chip(label: Text('4 FOUND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: Color(0xFF1E88E5)),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _extractedCovenants.length,
              itemBuilder: (context, i) {
                final cov = _extractedCovenants[i];
                final isSelected = _selectedCovenantIndex == i;
                return InkWell(
                  onTap: () => setState(() => _selectedCovenantIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E88E5).withOpacity(0.1) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF1E88E5) : Colors.transparent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cov['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            _buildStatusTag(cov['status']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.rule, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            Text('Term: ${cov['threshold']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            const Spacer(),
                            Text(cov['clause'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.verified),
              label: const Text('Confirm Extraction Audit'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color color = status == 'Compliant' ? Colors.green : (status == 'Warning' ? Colors.amber : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
