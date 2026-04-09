import 'package:flutter_test/flutter_test.dart';
import 'package:mfcalc/core/types/decimal_value.dart';
import 'package:mfcalc/features/finance_tools/domain/finance_calculators.dart';

void main() {
  group('FinanceCalculators', () {
    test('vat computes gross amount', () {
      final result = FinanceCalculators.vat(
        net: DecimalValue.parse('100'),
        rate: DecimalValue.parse('20'),
      );
      expect(result.toString(), '120');
    });

    test('simple interest computes maturity amount', () {
      final result = FinanceCalculators.simpleInterest(
        principal: DecimalValue.parse('1000'),
        annualRate: DecimalValue.parse('10'),
        days: 730,
      );
      expect(result.toString(), '1200');
    });

    test('compound interest computes daily maturity amount', () {
      final result = FinanceCalculators.compoundInterest(
        principal: DecimalValue.parse('1000'),
        annualRate: DecimalValue.parse('10'),
        days: 730,
      );
      expect(result.toString(), '1221.36930164');
    });
  });
}
