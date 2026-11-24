import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../theme/colors.dart';
import '../../utils/validators.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/input_field.dart';
import '../../widgets/loader.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/toast.dart';

class ServiceFormScreen extends StatefulWidget {
  final String mode;
  final String? serviceId;
  const ServiceFormScreen({super.key, required this.mode, this.serviceId});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'edit') _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await FirebaseService.getService(widget.serviceId!);
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description;
      _priceCtrl.text = s.price.toString();
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
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text) ?? 0,
      };
      if (widget.mode == 'add') {
        await FirebaseService.addService(data);
      } else {
        await FirebaseService.updateService(widget.serviceId!, data);
      }
      if (mounted) {
        Toast.show(
          context,
          widget.mode == 'add' ? 'Service created' : 'Service updated',
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

  Future<void> _delete() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete Service',
      message: 'Delete "${_nameCtrl.text}"? This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await FirebaseService.deleteService(widget.serviceId!);
      if (mounted) {
        Toast.show(context, 'Service deleted', isSuccess: true);
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
      appBar: AppBar(
        title: Text(widget.mode == 'edit' ? 'Edit Service' : 'Add Service'),
        actions: widget.mode == 'edit'
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  onPressed: _loading ? null : _delete,
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Loader(fullscreen: true, message: 'Loading...')
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    InputField(
                      label: 'Service Name *',
                      hint: 'e.g. Repair Service',
                      controller: _nameCtrl,
                      validator: (v) =>
                          Validators.required(v, label: 'Service name'),
                    ),
                    InputField(
                      label: 'Description',
                      hint: 'Optional description',
                      controller: _descCtrl,
                      maxLines: 3,
                    ),
                    InputField(
                      label: 'Price *',
                      hint: '0.00',
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) =>
                          Validators.positiveNumber(v, label: 'Price'),
                      prefix: const Text('\$ '),
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
}
