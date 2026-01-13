import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    final isExtended = MediaQuery.of(context).size.width > 1200;
    
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExtended,
            minExtendedWidth: 220,
            backgroundColor: const Color(0xFF0F172A),
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 40,
                    color: const Color(0xFF1E88E5),
                  ),
                  if (isExtended) ...[
                    const SizedBox(height: 8),
                    Text(
                      'CreditSentinel™',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Consumer<AuthService>(
              builder: (context, auth, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isExtended && auth.user != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user!['email'] ?? 'User',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              auth.user!['role']?.toUpperCase() ?? 'ANALYST',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    IconButton(
                      onPressed: () => _showLogoutDialog(context, auth),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined), 
                selectedIcon: Icon(Icons.dashboard), 
                label: Text('Dashboard')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description_outlined), 
                selectedIcon: Icon(Icons.description), 
                label: Text('Documents')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.monitor_heart_outlined), 
                selectedIcon: Icon(Icons.monitor_heart), 
                label: Text('Covenants')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_outlined), 
                selectedIcon: Icon(Icons.account_balance), 
                label: Text('Financials')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined), 
                selectedIcon: Icon(Icons.analytics), 
                label: Text('Simulator')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined), 
                selectedIcon: Icon(Icons.history), 
                label: Text('Audit Log')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.summarize_outlined), 
                selectedIcon: Icon(Icons.summarize), 
                label: Text('Reports')
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined), 
                selectedIcon: Icon(Icons.settings), 
                label: Text('Settings')
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.blueGrey, width: 0.5)),
      ),
      child: Row(
        children: [
          Text('CreditSentinel™', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(width: 48),
          _buildLoanDropdown(),
          const Spacer(),
          _buildSystemStatus(),
          const SizedBox(width: 24),
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildLoanDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.business, size: 18, color: Color(0xFF1E88E5)),
          SizedBox(width: 12),
          Text('Acme Corp - Senior Secured Term Loan', style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 12),
          Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        const Text('SECURE / ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildUserProfile() {
    return Row(
      children: [
        const Text('Josh Admin', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        CircleAvatar(radius: 18, backgroundColor: Colors.blueGrey[800], child: const Icon(Icons.person, size: 20)),
      ],
    );
  }
}
