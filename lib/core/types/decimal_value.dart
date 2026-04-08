import 'package:decimal/decimal.dart';

class DecimalValue {
  DecimalValue._(this.value);

  factory DecimalValue.parse(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    return DecimalValue._(Decimal.parse(normalized));
  }

  factory DecimalValue.fromInt(int value) =>
      DecimalValue._(Decimal.fromInt(value));
  factory DecimalValue.zero() => DecimalValue._(Decimal.zero);

  final Decimal value;

  DecimalValue plus(DecimalValue other) => DecimalValue._(value + other.value);
  DecimalValue minus(DecimalValue other) => DecimalValue._(value - other.value);
  DecimalValue times(DecimalValue other) => DecimalValue._(value * other.value);

  DecimalValue dividedBy(DecimalValue other, {int scale = 8}) {
    if (other.value == Decimal.zero) {
      throw ArgumentError('Division by zero.');
    }
    return DecimalValue._(
      (value / other.value).toDecimal(scaleOnInfinitePrecision: scale),
    );
  }

  DecimalValue percentOf(DecimalValue base) {
    return DecimalValue._(
      ((base.value * value) / Decimal.fromInt(100)).toDecimal(
        scaleOnInfinitePrecision: 8,
      ),
    );
  }

  DecimalValue round(int scale) {
    final s = value.toStringAsFixed(scale);
    return DecimalValue._(Decimal.parse(s));
  }

  DecimalValue negated() => DecimalValue._(-value);

  bool get isZero => value == Decimal.zero;

  @override
  String toString() => value.toString();
}
