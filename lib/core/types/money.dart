import 'package:intl/intl.dart';

import 'currency_code.dart';
import 'decimal_value.dart';

class Money {
  const Money({required this.amount, required this.currency});

  final DecimalValue amount;
  final CurrencyCode currency;

  String format({required String locale}) {
    final value = double.parse(amount.toString());
    final formatter = NumberFormat.currency(
      locale: locale,
      name: currency.code,
    );
    return formatter.format(value);
  }
}
