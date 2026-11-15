import 'package:flutter/material.dart';
import '../../api.dart';
import '../../models/models.dart';
import '../../theme/colors.dart';
import '../../utils/validators.dart';
import '../../widgets/input_field.dart';
import '../../widgets/loader.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/toast.dart';

class ProductFormScreen extends StatefulWidget {
  final String mode;
  final int? productId;
  const ProductFormScreen({super.key, required this.mode, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _unitPriceCtrl = TextEditingController();
  final _costPriceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _reorderCtrl = TextEditingController(text: '10');

  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  int? _categoryId;
  int? _supplierId;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final catsRes = await Api.request('get_categories');
      final supsRes = await Api.request('get_suppliers');
      _categories = (catsRes['categories'] as List? ?? [])
          .map((j) => Category.fromJson(j as Map<String, dynamic>))
          .toList();
      _suppliers = (supsRes['suppliers'] as List? ?? [])
          .map((j) => Supplier.fromJson(j as Map<String, dynamic>))
          .toList();

      if (widget.mode == 'edit' && widget.productId != null) {
        final res = await Api.request(
          'get_product',
          query: {'id': '${widget.productId}'},
        );
        final p = Product.fromJson(res['product'] as Map<String, dynamic>);
        _nameCtrl.text = p.name;
        _skuCtrl.text = p.sku;
        _descCtrl.text = p.description;
        _unitPriceCtrl.text = p.unitPrice.toString();
        _costPriceCtrl.text = p.costPrice.toString();
        _qtyCtrl.text = p.quantity.toString();
        _reorderCtrl.text = p.reorderLevel.toString();
        _categoryId = p.categoryId;
        _supplierId = p.supplierId;
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'sku': _skuCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category_id': _categoryId,
        'supplier_id': _supplierId,
        'unit_price': double.tryParse(_unitPriceCtrl.text) ?? 0,
        'cost_price': double.tryParse(_costPriceCtrl.text) ?? 0,
        'reorder_level': int.tryParse(_reorderCtrl.text) ?? 0,
      };
      if (widget.mode == 'add') {
        data['quantity'] = int.tryParse(_qtyCtrl.text) ?? 0;
        await Api.request('add_product', method: 'POST', data: data);
      } else {
        await Api.request(
          'update_product',
          method: 'PUT',
          query: {'id': '${widget.productId}'},
          data: data,
        );
      }
      if (mounted) {
        Toast.show(
          context,
          widget.mode == 'add' ? 'Product created' : 'Product updated',
          isSuccess: true,
        );
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'edit' ? 'Edit Product' : 'Add Product'),
      ),
      body: _loading
          ? const Loader(fullscreen: true, message: 'Loading…')
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    InputField(
                      label: 'Product Name *',
                      hint: 'e.g. Wireless Mouse',
                      controller: _nameCtrl,
                      validator: (v) =>
                          Validators.required(v, label: 'Product name'),
                    ),
                    InputField(
                      label: 'SKU *',
                      hint: 'Unique stock-keeping unit',
                      controller: _skuCtrl,
                      validator: Validators.sku,
                      helperText: 'Letters, numbers, - and _ only',
                    ),
                    InputField(
                      label: 'Description',
                      hint: 'Optional product description',
                      controller: _descCtrl,
                      maxLines: 3,
                    ),
                    _dropdown(
                      label: 'Category',
                      value: _categoryId,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    _dropdown(
                      label: 'Supplier',
                      value: _supplierId,
                      items: _suppliers
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _supplierId = v),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: InputField(
                            label: 'Unit Price *',
                            hint: '0.00',
                            controller: _unitPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) => Validators.positiveNumber(
                              v,
                              label: 'Unit price',
                            ),
                            prefix: const Text('\$ '),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: InputField(
                            label: 'Cost Price *',
                            hint: '0.00',
                            controller: _costPriceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) => Validators.positiveNumber(
                              v,
                              label: 'Cost price',
                            ),
                            prefix: const Text('\$ '),
                          ),
                        ),
                      ],
                    ),
                    if (widget.mode == 'add')
                      InputField(
                        label: 'Initial Quantity *',
                        hint: '0',
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveInt(
                          v,
                          label: 'Initial quantity',
                        ),
                        helperText:
                            'A STOCK_IN transaction will be created automatically.',
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Quantity',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Use Stock In / Out to adjust',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _qtyCtrl.text,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    InputField(
                      label: 'Reorder Level *',
                      hint: '10',
                      controller: _reorderCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          Validators.positiveInt(v, label: 'Reorder level'),
                      helperText: 'Low-stock alert triggers at this level.',
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
                            label: widget.mode == 'add' ? 'Create' : 'Save',
                            loading: _saving,
                            onPressed: _save,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _dropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            initialValue: value,
            decoration: const InputDecoration(hintText: 'Select…'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ...items,
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
