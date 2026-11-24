class Validators {
  static String? required(String? v, {String label = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? minLength(String? v, int n, {String label = 'This field'}) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length < n) return '$label must be at least $n characters';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());
    if (!ok) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final cleaned = v.replaceAll(RegExp(r'[\s\-()+]'), '');
    if (!RegExp(r'^\d{6,15}$').hasMatch(cleaned)) {
      return 'Enter a valid phone (6-15 digits)';
    }
    return null;
  }

  static String? positiveNumber(String? v, {String label = 'Value'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final n = double.tryParse(v.trim());
    if (n == null) return '$label must be a number';
    if (n < 0) return '$label cannot be negative';
    return null;
  }

  static String? positiveInt(
    String? v, {
    String label = 'Quantity',
    bool allowZero = true,
  }) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    final n = int.tryParse(v.trim());
    if (n == null) return '$label must be a whole number';
    if (n < 0) return '$label cannot be negative';
    if (!allowZero && n <= 0) return '$label must be greater than zero';
    return null;
  }

  static String? sku(String? v) {
    if (v == null || v.trim().isEmpty) return 'SKU is required';
    if (v.length > 30) return 'SKU must be at most 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(v)) {
      return 'SKU can only contain letters, numbers, - and _';
    }
    return null;
  }
}
