import 'package:flutter/material.dart';
import '../api.dart';
import '../models/models.dart';
import '../theme/colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/loader.dart';
import '../widgets/primary_button.dart';
import '../widgets/toast.dart';
import '../utils/validators.dart';
import 'products/products_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];
  Map<int, int> _counts = {};
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
      final res = await Api.request('get_categories');
      final list = (res['categories'] as List? ?? [])
          .map((j) => Category.fromJson(j as Map<String, dynamic>))
          .toList();
      final counts = <int, int>{};
      for (final j in (res['categories'] as List? ?? [])) {
        final map = j as Map<String, dynamic>;
        final id = int.tryParse('${map['id']}') ?? 0;
        counts[id] = int.tryParse('${map['product_count'] ?? 0}') ?? 0;
      }
      if (mounted) {
        setState(() {
          _categories = list;
          _counts = counts;
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

  Future<void> _openForm([Category? cat]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _CategoryFormDialog(category: cat),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Category cat) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete Category',
      message:
          'Delete "${cat.name}"? Products in it will become Uncategorized.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await Api.request(
        'delete_category',
        method: 'DELETE',
        query: {'id': '${cat.id}'},
      );
      if (mounted) {
        Toast.show(context, 'Category deleted', isSuccess: true);
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
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _loading ? null : () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const Loader(fullscreen: true, message: 'Loading categories…')
          : _error != null
          ? EmptyState(
              title: 'Failed to load',
              message: _error,
              icon: Icons.error_outline,
            )
          : _categories.isEmpty
          ? const EmptyState(
              title: 'No categories',
              message: 'Tap + to create your first category.',
              icon: Icons.category_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final c = _categories[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductsListScreen(presetCategoryId: c.id),
                          ),
                        );
                      },
                      title: Text(
                        c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                c.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_counts[c.id] ?? 0} products',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: AppColors.primary,
                            onPressed: () => _openForm(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppColors.danger,
                            onPressed: () => _delete(c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final Category? category;
  const _CategoryFormDialog({this.category});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _descCtrl.text = widget.category!.description;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      };
      if (widget.category == null) {
        await Api.request('add_category', method: 'POST', data: data);
      } else {
        await Api.request(
          'update_category',
          method: 'PUT',
          query: {'id': '${widget.category!.id}'},
          data: data,
        );
      }
      if (mounted) {
        Toast.show(
          context,
          widget.category == null ? 'Category created' : 'Category updated',
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
    return AlertDialog(
      title: Text(widget.category == null ? 'New Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => Validators.required(v, label: 'Category name'),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        PrimaryButton(
          label: 'Cancel',
          outline: true,
          color: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PrimaryButton(
          label: widget.category == null ? 'Create' : 'Save',
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
