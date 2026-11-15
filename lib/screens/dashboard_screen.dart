import 'package:flutter/material.dart';
import '../api.dart';
import '../models/models.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loader.dart';
import '../widgets/stat_card.dart';
import 'products/products_list_screen.dart';
import 'products/product_detail_screen.dart';
import 'products/product_form_screen.dart';
import 'stock_movement_screen.dart';
import 'transactions_screen.dart';
import 'low_stock_screen.dart';
import 'categories_screen.dart';
import 'services/services_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  List<Product> _lowStock = [];
  List<StockMovement> _recent = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final statsRes = await Api.request('dashboard_stats');
      final lowRes = await Api.request('get_low_stock');
      final txRes = await Api.request(
        'get_transactions',
        query: {'limit': '5'},
      );

      final stats = DashboardStats.fromJson(statsRes);
      final low = (lowRes['products'] as List? ?? [])
          .map((j) => Product.fromJson(j as Map<String, dynamic>))
          .toList();
      final recent = (txRes['transactions'] as List? ?? [])
          .map((j) => StockMovement.fromJson(j as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _stats = stats;
          _lowStock = low;
          _recent = recent;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _openProduct(int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: id)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Loader(fullscreen: true, message: 'Loading dashboard...')
            : _error != null
            ? EmptyState(
                title: 'Failed to load',
                message: _error,
                icon: Icons.error_outline,
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final s = _stats!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              label: 'Total Products',
              value: Formatters.number(s.totalProducts),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProductsListScreen())),
            ),
            StatCard(
              label: 'In Stock',
              value: Formatters.number(s.totalStockUnits),
              accent: AppColors.secondary,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProductsListScreen())),
            ),
            StatCard(
              label: 'Low Stock',
              value: Formatters.number(s.lowStockCount),
              accent: s.lowStockCount > 0
                  ? AppColors.warning
                  : AppColors.secondary,
              badge: s.lowStockCount,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => LowStockScreen())),
            ),
            StatCard(
              label: 'Services',
              value: Formatters.number(s.totalServices),
              accent: AppColors.info,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ServicesListScreen())),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory Value (at cost)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.currency(s.inventoryValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${s.totalCategories} categories - ${s.totalSuppliers} suppliers',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _quickAction(
              'Add Product',
              Icons.add_circle,
              AppColors.primary,
              () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => ProductFormScreen(mode: 'add'),
                      ),
                    )
                    .then((_) => _load());
              },
            ),
            _quickAction(
              'Stock In',
              Icons.arrow_downward,
              AppColors.secondary,
              () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => StockMovementScreen(mode: 'STOCK_IN'),
                      ),
                    )
                    .then((_) => _load());
              },
            ),
            _quickAction('Stock Out', Icons.arrow_upward, AppColors.danger, () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => StockMovementScreen(mode: 'STOCK_OUT'),
                    ),
                  )
                  .then((_) => _load());
            }),
            _quickAction('History', Icons.history, AppColors.info, () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => TransactionsScreen()));
            }),
            _quickAction(
              'Categories',
              Icons.category_outlined,
              AppColors.warning,
              () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => CategoriesScreen()))
                    .then((_) => _load());
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _sectionHeader(
          'Low Stock Alerts',
          action: _lowStock.isNotEmpty
              ? GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => LowStockScreen())),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        if (_lowStock.isEmpty)
          _emptyInline('All products are above their reorder levels.')
        else
          ..._lowStock.take(3).map((p) => _lowStockRow(p)),
        const SizedBox(height: AppSpacing.lg),
        _sectionHeader(
          'Recent Activity',
          action: _recent.isNotEmpty
              ? GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TransactionsScreen()),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        if (_recent.isEmpty)
          _emptyInline('No transactions yet.')
        else
          ..._recent.map((tx) => _txRow(tx)),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          ?action,
        ],
      ),
    );
  }

  Widget _emptyInline(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  Widget _lowStockRow(Product p) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => _openProduct(p.id),
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${p.categoryName ?? 'Uncategorized'} - SKU ${p.sku}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${p.quantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.warning,
              ),
            ),
            Text(
              '/ ${p.reorderLevel}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _txRow(StockMovement tx) {
    final meta = MovementMeta.forType(tx.type);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: () => _openProduct(tx.productId),
        leading: CircleAvatar(
          backgroundColor: Color(meta.color),
          radius: 16,
          child: Text(
            meta.sign,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          tx.productName ?? 'Product #${tx.productId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${meta.label} - ${Formatters.relativeTime(tx.createdAt)}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Text(
          '${meta.sign}${tx.quantity}',
          style: TextStyle(
            color: Color(meta.color),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
