import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products/products_list_screen.dart';
import 'screens/services/services_list_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/profile_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _index = 0;

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(),
      ProductsListScreen(),
      ServicesListScreen(),
      TransactionsScreen(),
      ProfileScreen(onLogout: _logout),
    ];

    final labels = [
      'Dashboard',
      'Products',
      'Services',
      'Transactions',
      'Profile',
    ];
    final icons = [
      Icons.dashboard_outlined,
      Icons.inventory_2_outlined,
      Icons.miscellaneous_services_outlined,
      Icons.receipt_long_outlined,
      Icons.person_outline,
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        destinations: List.generate(5, (i) {
          return NavigationDestination(
            icon: Icon(icons[i]),
            selectedIcon: Icon(icons[i], color: AppColors.primary),
            label: labels[i],
          );
        }),
      ),
    );
  }
}
