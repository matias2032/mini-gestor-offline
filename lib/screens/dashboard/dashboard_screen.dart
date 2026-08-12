import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _openModule(BuildContext context, String moduleName) {
    // TODO: replace with Navigator.of(context).pushNamed('/$moduleName')
    // once each module screen is built.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$moduleName" module is still under construction.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final greetingName = user?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetingName.isNotEmpty ? 'Hello, $greetingName' : 'Hello',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'What would you like to manage today?',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _ModuleCard(
                      icon: Icons.people_outline,
                      label: 'Customers',
                      onTap: () => Navigator.of(context).pushNamed('/customer'),
                    ),
                    _ModuleCard(
                      icon: Icons.local_shipping_outlined,
                      label: 'Suppliers',
                      onTap: () => Navigator.of(context).pushNamed('/supplier'),
                    ),
                    _ModuleCard(
                      icon: Icons.point_of_sale_outlined,
                      label: 'Sales',
                      onTap: () => _openModule(context, 'sale'),
                    ),
                    _ModuleCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Expenses',
                      onTap: () => Navigator.pushNamed(context, '/expense'),
                    ),
                    _ModuleCard(
                      icon: Icons.category_outlined,
                      label: 'Expense Categories',
                      onTap: () =>
                          Navigator.pushNamed(context, '/expense-category'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}