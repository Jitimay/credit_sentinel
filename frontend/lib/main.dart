import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'widgets/app_shell.dart';
import 'pages/dashboard_page.dart';
import 'pages/documents_page.dart';
import 'pages/simulation_page.dart';
import 'pages/audit_log_page.dart';
import 'pages/upload_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  await authService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const CreditSentinelApp(),
    ),
  );
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
          surface: const Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? const MainScreen() : const LoginPage();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const DocumentsPage(),
    const PlaceholderWidget(title: "Covenants"), // Missing page
    const UploadPage(), // Financials / Upload
    const SimulationPage(),
    const AuditLogPage(),
    const PlaceholderWidget(title: "Reports"), // Missing page
    const PlaceholderWidget(title: "Settings"), // Missing page
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      child: _pages[_selectedIndex],
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            '$title Page',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Under Construction',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
