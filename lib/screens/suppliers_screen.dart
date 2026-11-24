import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../theme/colors.dart';
import '../utils/validators.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/input_field.dart';
import '../widgets/loader.dart';
import '../widgets/primary_button.dart';
import '../widgets/toast.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _suppliers = [];
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
      final sups = await FirebaseService.getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = sups;
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

  Future<void> _openForm([Supplier? sup]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SupplierFormSheet(supplier: sup),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Supplier sup) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete Supplier',
      message:
          'Delete "${sup.name}"? Linked products will lose their supplier.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await FirebaseService.deleteSupplier(sup.id);
      if (mounted) {
        Toast.show(context, 'Supplier deleted', isSuccess: true);
        _load();
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
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _loading ? null : () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const Loader(fullscreen: true, message: 'Loading suppliers...')
          : _error != null
          ? EmptyState(
              title: 'Failed to load',
              message: _error,
              icon: Icons.error_outline,
            )
          : _suppliers.isEmpty
          ? const EmptyState(
              title: 'No suppliers',
              message: 'Tap + to add your first supplier.',
              icon: Icons.local_shipping_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _suppliers.length,
                itemBuilder: (_, i) {
                  final s = _suppliers[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      onTap: () => _openForm(s),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s.phone.isNotEmpty)
                            Text(
                              'Phone: ${s.phone}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (s.email.isNotEmpty)
                            Text(
                              'Email: ${s.email}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (s.address.isNotEmpty)
                            Text(
                              'Address: ${s.address}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.danger,
                        onPressed: () => _delete(s),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _SupplierFormSheet extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierFormSheet({this.supplier});

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      final s = widget.supplier!;
      _nameCtrl.text = s.name;
      _phoneCtrl.text = s.phone;
      _emailCtrl.text = s.email;
      _addressCtrl.text = s.address;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      };
      if (widget.supplier == null) {
        await FirebaseService.addSupplier(data);
      } else {
        await FirebaseService.updateSupplier(widget.supplier!.id, data);
      }
      if (mounted) {
        Toast.show(
          context,
          widget.supplier == null ? 'Supplier created' : 'Supplier updated',
          isSuccess: true,
        );
        Navigator.of(context).pop(true);
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
    final padding = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.supplier == null ? 'New Supplier' : 'Edit Supplier',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              InputField(
                label: 'Name *',
                controller: _nameCtrl,
                validator: (v) =>
                    Validators.required(v, label: 'Supplier name'),
              ),
              InputField(
                label: 'Phone',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              InputField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              InputField(
                label: 'Address',
                controller: _addressCtrl,
                maxLines: 2,
              ),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Cancel',
                      outline: true,
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: widget.supplier == null ? 'Create' : 'Save',
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
