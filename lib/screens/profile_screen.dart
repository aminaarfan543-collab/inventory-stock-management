import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../theme/colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/loader.dart';
import 'categories_screen.dart';
import 'suppliers_screen.dart';
import 'services/services_list_screen.dart';
import 'transactions_screen.dart';
import 'low_stock_screen.dart';
import 'products/products_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await FirebaseService.getUserData();
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Loader(fullscreen: true);
    final name = _user?['full_name'] ?? 'User';
    final email = _user?['email'] ?? '-';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'MANAGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                _menuRow(
                  Icons.inventory_2_outlined,
                  'Products',
                  AppColors.primary,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ProductsListScreen()),
                    );
                  },
                ),
                _divider(),
                _menuRow(
                  Icons.category_outlined,
                  'Categories',
                  AppColors.info,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CategoriesScreen()),
                    );
                  },
                ),
                _divider(),
                _menuRow(
                  Icons.local_shipping_outlined,
                  'Suppliers',
                  AppColors.secondary,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SuppliersScreen()),
                    );
                  },
                ),
                _divider(),
                _menuRow(
                  Icons.miscellaneous_services_outlined,
                  'Services',
                  AppColors.info,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ServicesListScreen()),
                    );
                  },
                ),
                _divider(),
                _menuRow(
                  Icons.receipt_long_outlined,
                  'Transactions',
                  AppColors.warning,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const TransactionsScreen()),
                    );
                  },
                ),
                _divider(),
                _menuRow(
                  Icons.warning_amber_outlined,
                  'Low Stock Alerts',
                  AppColors.danger,
                  () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(
                        builder: (_) => const LowStockScreen()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                _infoRow('App Name', 'Inventory Manager'),
                _divider(),
                _infoRow('Version', '1.0.0'),
                _divider(),
                _infoRow('Backend', 'Firebase'),
                _divider(),
                _infoRow('AI Features', 'None - fully deterministic'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await ConfirmDialog.show(
                context,
                title: 'Log Out',
                message: 'Are you sure you want to log out?',
                confirmLabel: 'Log Out',
                destructive: true,
              );
              if (ok) {
                await FirebaseService.logout();
                widget.onLogout();
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        radius: 16,
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: AppColors.divider);
}
