import 'package:intl/intl.dart';

import '../../features/settings/domain/display_settings.dart';

class NumberDisplayFormatter {
  static String format({
    required String raw,
    required String locale,
    required DisplaySettings settings,
  }) {
    final normalized = raw.replaceAll(',', '.').trim();

    // Keep in-progress input like "12." visible while typing.
    if (normalized.endsWith('.')) {
      final prefix = normalized.substring(0, normalized.length - 1);
      final head = _formatParsed(prefix, locale, settings);
      final decimal = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
      return '$head$decimal';
    }

    return _formatParsed(normalized, locale, settings);
  }

  static String _formatParsed(
    String normalized,
    String locale,
    DisplaySettings settings,
  ) {
    final value = double.tryParse(normalized);
    if (value == null) return normalized;

    if (settings.useGrouping) {
      return NumberFormat.decimalPatternDigits(
        locale: locale,
        decimalDigits: settings.decimalDigits,
      ).format(value);
    }

    final decimals = settings.decimalDigits;
    final fixed = value.toStringAsFixed(decimals);
    if (decimals == 0) return fixed;

    final parts = fixed.split('.');
    final decimal = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
    return '${parts[0]}$decimal${parts[1]}';
  }
}
