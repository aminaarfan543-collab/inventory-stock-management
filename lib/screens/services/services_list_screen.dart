import 'package:flutter/material.dart';
import '../../api.dart';
import '../../models/models.dart';
import '../../theme/colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loader.dart';
import 'service_form_screen.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  List<Service> _services = [];
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
      final res = await Api.request('get_services');
      if (mounted) {
        setState(() {
          _services = (res['services'] as List? ?? [])
              .map((j) => Service.fromJson(j as Map<String, dynamic>))
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
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'services_fab',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ServiceFormScreen(mode: 'add'),
            ),
          );
          _load();
        },
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Loader(fullscreen: true, message: 'Loading services...')
          : _error != null
          ? EmptyState(
              title: 'Failed to load',
              message: _error,
              icon: Icons.error_outline,
            )
          : _services.isEmpty
          ? const EmptyState(
              title: 'No services',
              message: 'Tap the + button to add your first service.',
              icon: Icons.miscellaneous_services_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _services.length,
                itemBuilder: (_, i) {
                  final s = _services[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ServiceFormScreen(
                              mode: 'edit',
                              serviceId: s.id,
                            ),
                          ),
                        );
                        _load();
                      },
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        s.description.isEmpty
                            ? 'No description'
                            : s.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        Formatters.currency(s.price),
                        style: const TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
