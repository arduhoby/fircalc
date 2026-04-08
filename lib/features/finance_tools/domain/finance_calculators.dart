import '../../../core/types/decimal_value.dart';

class FinanceCalculators {
  static DecimalValue percentage({
    required DecimalValue base,
    required DecimalValue rate,
  }) {
    return rate.percentOf(base);
  }

  static DecimalValue vat({
    required DecimalValue net,
    required DecimalValue rate,
  }) {
    return net.plus(rate.percentOf(net));
  }

  static DecimalValue simpleInterest({
    required DecimalValue principal,
    required DecimalValue annualRate,
    required int years,
  }) {
    final interest = annualRate
        .percentOf(principal)
        .times(DecimalValue.fromInt(years));
    return principal.plus(interest);
  }

  static DecimalValue compoundInterest({
    required DecimalValue principal,
    required DecimalValue annualRate,
    required int years,
  }) {
    var total = principal;
    final step = annualRate.dividedBy(DecimalValue.fromInt(100));
    for (var i = 0; i < years; i++) {
      total = total.plus(total.times(step));
    }
    return total;
  }
}
