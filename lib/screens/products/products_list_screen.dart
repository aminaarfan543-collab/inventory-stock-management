import 'package:flutter/material.dart';
import '../../api.dart';
import '../../models/models.dart';
import '../../theme/colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loader.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductsListScreen extends StatefulWidget {
  final int? presetCategoryId;
  const ProductsListScreen({super.key, this.presetCategoryId});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int? _activeCategory;
  bool _lowOnly = false;
  String _sort = 'name_asc';

  @override
  void initState() {
    super.initState();
    _activeCategory = widget.presetCategoryId;
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final res = await Api.request('get_categories');
      if (mounted) {
        setState(() {
          _categories = (res['categories'] as List? ?? [])
              .map((j) => Category.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = <String, String>{
        if (_search.trim().isNotEmpty) 'search': _search.trim(),
        if (_activeCategory != null) 'category_id': '$_activeCategory',
        if (_lowOnly) 'low_stock': '1',
        'sort': _sort,
      };
      final res = await Api.request('get_products', query: query);
      if (mounted) {
        setState(() {
          _products = (res['products'] as List? ?? [])
              .map((j) => Product.fromJson(j as Map<String, dynamic>))
              .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'products_fab',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(mode: 'add'),
            ),
          );
          _loadProducts();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              onChanged: (v) => _search = v,
              onSubmitted: (_) => _loadProducts(),
              decoration: InputDecoration(
                hintText: 'Search by name or SKU...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() => _search = '');
                          _loadProducts();
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _chip('All', _activeCategory == null, () {
                    setState(() => _activeCategory = null);
                    _loadProducts();
                  }),
                  ..._categories.map(
                    (c) => _chip(c.name, _activeCategory == c.id, () {
                      setState(() => _activeCategory = c.id);
                      _loadProducts();
                    }),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                FilterChip(
                  label: const Text(
                    'Low stock only',
                    style: TextStyle(fontSize: 11),
                  ),
                  selected: _lowOnly,
                  onSelected: (v) {
                    setState(() => _lowOnly = v);
                    _loadProducts();
                  },
                  selectedColor: AppColors.warningLight,
                  labelStyle: TextStyle(
                    color: _lowOnly
                        ? AppColors.warning
                        : AppColors.textSecondary,
                    fontWeight: _lowOnly ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'name_asc',
                      child: Text('Name ^', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'name_desc',
                      child: Text('Name v', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'stock_asc',
                      child: Text('Stock ^', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'stock_desc',
                      child: Text('Stock v', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Text('Price ^', style: TextStyle(fontSize: 12)),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text('Price v', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _sort = v);
                    _loadProducts();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Loader(fullscreen: true, message: 'Loading products...')
                : _error != null
                ? EmptyState(
                    title: 'Failed to load',
                    message: _error,
                    icon: Icons.error_outline,
                  )
                : _products.isEmpty
                ? EmptyState(
                    title: 'No products found',
                    message:
                        _search.isNotEmpty ||
                            _activeCategory != null ||
                            _lowOnly
                        ? 'Try adjusting your filters.'
                        : 'Tap the + button to add your first product.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => _productCard(_products[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _productCard(Product p) {
    final oos = p.isOutOfStock;
    final low = !oos && p.isLowStock;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: p.id),
            ),
          );
          _loadProducts();
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (oos)
              _statusPill('Out of stock', AppColors.danger)
            else if (low)
              _statusPill('Low', AppColors.warning),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${p.categoryName ?? 'Uncategorized'} - SKU ${p.sku}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.currency(p.unitPrice),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${p.quantity}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: oos
                    ? AppColors.danger
                    : low
                    ? AppColors.warning
                    : AppColors.textPrimary,
              ),
            ),
            const Text(
              'in stock',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
