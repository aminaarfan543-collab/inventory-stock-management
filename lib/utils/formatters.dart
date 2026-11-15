import 'package:intl/intl.dart';

class Formatters {
  static String currency(double value) {
    return NumberFormat.currency(
      symbol: 'Rs ',
      decimalDigits: 2,
      locale: 'en_PK',
    ).format(value);
  }

  static String number(num value) {
    return NumberFormat.decimalPattern().format(value);
  }

  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('MMM dd, yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  static String dateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('MMM dd, yyyy · hh:mm a').format(d);
    } catch (_) {
      return iso;
    }
  }

  static String relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final then = DateTime.parse(iso).millisecondsSinceEpoch;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diffSec = ((now - then) / 1000).floor();
      if (diffSec < 60) return 'just now';
      if (diffSec < 3600) return '${(diffSec / 60).floor()}m ago';
      if (diffSec < 86400) return '${(diffSec / 3600).floor()}h ago';
      if (diffSec < 604800) return '${(diffSec / 86400).floor()}d ago';
      return date(iso);
    } catch (_) {
      return iso;
    }
  }

  static String truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 1)}…';
  }
}

class MovementMeta {
  final String label;
  final String sign;
  final int color;
  const MovementMeta(this.label, this.sign, this.color);

  static const stockIn = MovementMeta('Stock In', '+', 0xFF10B981);
  static const stockOut = MovementMeta('Stock Out', '-', 0xFFE02424);
  static const adjustment = MovementMeta('Adjustment', '±', 0xFFF59E0B);

  static MovementMeta forType(String type) {
    switch (type) {
      case 'STOCK_IN':
      case 'stock_in':
      case 'in':
        return stockIn;
      case 'STOCK_OUT':
      case 'stock_out':
      case 'out':
        return stockOut;
      default:
        return adjustment;
    }
  }
}
