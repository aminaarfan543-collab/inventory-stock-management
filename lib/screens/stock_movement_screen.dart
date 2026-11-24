import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/colors.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/empty_state.dart';
import '../widgets/input_field.dart';
import '../widgets/loader.dart';
import '../widgets/primary_button.dart';
import '../widgets/toast.dart';

class StockMovementScreen extends StatefulWidget {
  final String mode;
  final String? productId;
  const StockMovementScreen({super.key, required this.mode, this.productId});

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  List<Product> _products = [];
  Product? _selected;
  final _qtyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _qtyError;
  bool _loading = true;
  bool _saving = false;

  bool get isOut => widget.mode == 'STOCK_OUT';
  Color get accent => isOut ? AppColors.danger : AppColors.secondary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await FirebaseService.getProducts();
      if (mounted) {
        setState(() {
          _products = isOut ? list.where((p) => p.quantity > 0).toList() : list;
          if (widget.productId != null) {
            try {
              _selected = _products.firstWhere((p) => p.id == widget.productId);
            } catch (_) {
              _selected = list.firstWhere((p) => p.id == widget.productId);
            }
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_selected == null) {
      Toast.show(context, 'Select a product first', isError: true);
      return;
    }
    final err = Validators.positiveInt(
      _qtyCtrl.text,
      label: 'Quantity',
      allowZero: false,
    );
    setState(() => _qtyError = err);
    if (err != null) return;

    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    if (isOut && qty > _selected!.quantity) {
      setState(
        () => _qtyError =
            'Only ${_selected!.quantity} in stock - cannot remove $qty',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final newQty = await FirebaseService.stockMovement(
        _selected!.id,
        widget.mode,
        qty,
        _noteCtrl.text.trim(),
      );
      await _load();
      if (_selected != null) {
        try {
          _selected = _products.firstWhere((p) => p.id == _selected!.id);
        } catch (_) {}
      }
      if (mounted) {
        Toast.show(
          context,
          isOut
              ? 'Removed $qty unit(s). New stock: $newQty'
              : 'Added $qty unit(s). New stock: $newQty',
          isSuccess: true,
        );
        setState(() {
          _qtyCtrl.clear();
          _noteCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        Toast.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isOut ? 'Stock Out' : 'Stock In')),
      body: _loading
          ? const Loader(fullscreen: true, message: 'Loading products...')
          : SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    color: accent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOut ? 'Record Stock Out' : 'Record Stock In',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isOut
                              ? 'Remove units (sold, damaged, returned to supplier).'
                              : 'Add units (new delivery, customer return).',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selected == null ? _productPicker() : _formView(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _productPicker() {
    if (_products.isEmpty) {
      return const EmptyState(
        title: 'No products',
        message: 'Add a product first to record stock movements.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final p = _products[i];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListTile(
            onTap: () => setState(() => _selected = p),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'SKU ${p.sku}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              '${p.quantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _formView() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU ${_selected!.sku} - ${Formatters.currency(_selected!.unitPrice)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Current stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${_selected!.quantity}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                TextButton(
                  onPressed: () => setState(() => _selected = null),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InputField(
          label: 'Quantity *',
          hint: 'e.g. 25',
          controller: _qtyCtrl,
          keyboardType: TextInputType.number,
          errorText: _qtyError,
          helperText: isOut ? 'Max removable: ${_selected!.quantity}' : null,
          onChanged: (_) => setState(() => _qtyError = null),
        ),
        InputField(
          label: 'Note (optional)',
          hint: 'Reason for this movement',
          controller: _noteCtrl,
          maxLines: 2,
          maxLength: 250,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: 'Cancel',
                outline: true,
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                label: isOut ? 'Remove Stock' : 'Add Stock',
                color: accent,
                loading: _saving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
