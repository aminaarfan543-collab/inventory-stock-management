import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../theme/colors.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/toast.dart';
import '../../utils/validators.dart';
import '../../main_app.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _confirmError = 'Passwords do not match');
      return;
    }
    setState(() => _confirmError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseService.register(
        _emailCtrl.text,
        _passwordCtrl.text,
        _nameCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainApp()),
          (_) => false,
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Set up your store manager account to start tracking inventory.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        InputField(
                          label: 'Full Name',
                          hint: 'e.g. Jane Smith',
                          controller: _nameCtrl,
                          capitalization: TextCapitalization.words,
                          validator: (v) =>
                              Validators.required(v, label: 'Full name'),
                          prefix: const Icon(Icons.person_outline, size: 20),
                        ),
                        InputField(
                          label: 'Email',
                          hint: 'e.g. jane@example.com',
                          controller: _emailCtrl,
                          validator: Validators.email,
                          keyboardType: TextInputType.emailAddress,
                          prefix: const Icon(Icons.email_outlined, size: 20),
                        ),
                        InputField(
                          label: 'Password',
                          hint: 'At least 6 characters',
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          validator: Validators.password,
                          prefix: const Icon(Icons.lock_outline, size: 20),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        InputField(
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          controller: _confirmCtrl,
                          obscureText: _obscurePassword,
                          errorText: _confirmError,
                          prefix: const Icon(Icons.lock_outline, size: 20),
                        ),
                        PrimaryButton(
                          label: 'Create Account',
                          loading: _loading,
                          onPressed: _register,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
