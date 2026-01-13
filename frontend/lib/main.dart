import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'widgets/app_shell.dart';
import 'pages/dashboard_page.dart';
import 'pages/documents_page.dart';
import 'pages/simulation_page.dart';
import 'pages/audit_log_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ProxyProvider<AuthService, ApiService>(
          update: (_, auth, __) => ApiService(auth),
        ),
      ],
      child: const CreditSentinelApp(),
    ),
  );
}

class CreditSentinelApp extends StatefulWidget {
  const CreditSentinelApp({super.key});

  @override
  State<CreditSentinelApp> createState() => _CreditSentinelAppState();
}

class _CreditSentinelAppState extends State<CreditSentinelApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const DocumentsPage(),
    const Center(child: Text('Covenant Monitor (Coming Next)')),
    const Center(child: Text('Financials (Coming Next)')),
    const SimulationPage(),
    const AuditLogPage(),
    const Center(child: Text('Reports (Coming Next)')),
    const Center(child: Text('Settings (Coming Next)')),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CreditSentinel',
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
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          headlineMedium: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), 
          brightness: Brightness.dark, 
          secondary: const Color(0xFF10B981)
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: const Color(0xFF1E293B),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginPage();
          }
          return AppShell(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            child: _pages[_selectedIndex],
          );
        },
      ),
    );
  }
}
