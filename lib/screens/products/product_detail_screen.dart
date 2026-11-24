import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../theme/colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loader.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/toast.dart';
import 'product_form_screen.dart';
import '../stock_movement_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  List<StockMovement> _history = [];
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
      final p = await FirebaseService.getProduct(widget.productId);
      final txs = await FirebaseService.getTransactions(
        productId: widget.productId,
      );
      if (mounted) {
        setState(() {
          _product = p;
          _history = txs;
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

  Future<void> _delete() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete Product',
      message:
          'Delete "${_product!.name}"? This will also remove its transaction history.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await FirebaseService.deleteProduct(_product!.id);
      if (mounted) {
        Toast.show(context, 'Product deleted', isSuccess: true);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Detail')),
      body: _loading
          ? const Loader(fullscreen: true, message: 'Loading product...')
          : _error != null
              ? EmptyState(
                  title: 'Failed to load',
                  message: _error,
                  icon: Icons.error_outline,
                )
              : _product == null
                  ? const EmptyState(title: 'Product not found')
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          _headerCard(),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Stock In',
                                  color: AppColors.secondary,
                                  icon: Icons.arrow_downward,
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => StockMovementScreen(
                                          mode: 'STOCK_IN',
                                          productId: _product!.id,
                                        ),
                                      ),
                                    );
                                    _load();
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Stock Out',
                                  color: AppColors.danger,
                                  icon: Icons.arrow_upward,
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => StockMovementScreen(
                                          mode: 'STOCK_OUT',
                                          productId: _product!.id,
                                        ),
                                      ),
                                    );
                                    _load();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _infoCard(),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Edit',
                                  outline: true,
                                  icon: Icons.edit_outlined,
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProductFormScreen(
                                          mode: 'edit',
                                          productId: _product!.id,
                                        ),
                                      ),
                                    );
                                    _load();
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Delete',
                                  color: AppColors.danger,
                                  icon: Icons.delete_outline,
                                  onPressed: _delete,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          const Text(
                            'Stock History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_history.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Text(
                                'No stock movements yet.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ..._history.map(_historyRow),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                      ),
                    ),
    );
  }

  Widget _headerCard() {
    final p = _product!;
    final oos = p.isOutOfStock;
    final low = !oos && p.isLowStock;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${p.sku}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.quantity}',
                      style: TextStyle(
                        fontSize: 28,
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
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (oos || low) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (oos ? AppColors.danger : AppColors.warning)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  oos
                      ? 'Out of stock - reorder required'
                      : 'Low stock - only ${p.quantity} units left (reorder at ${p.reorderLevel})',
                  style: TextStyle(
                    color: oos ? AppColors.danger : AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final p = _product!;
    return Card(
      child: Column(
        children: [
          _infoRow('Category', p.categoryName ?? 'Uncategorized'),
          _infoRow('Supplier', p.supplierName ?? '-'),
          _infoRow('Unit Price', Formatters.currency(p.unitPrice)),
          _infoRow('Cost Price', Formatters.currency(p.costPrice)),
          _infoRow('Margin', Formatters.currency(p.unitPrice - p.costPrice)),
          _infoRow('Reorder Level', '${p.reorderLevel} units'),
          _infoRow('Created', Formatters.date(p.createdAt)),
          if (p.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(p.description, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyRow(StockMovement tx) {
    final meta = MovementMeta.forType(tx.type);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
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
          meta.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Formatters.dateTime(tx.createdAt),
              style: const TextStyle(fontSize: 11),
            ),
            if (tx.note.isNotEmpty)
              Text(
                tx.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
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
