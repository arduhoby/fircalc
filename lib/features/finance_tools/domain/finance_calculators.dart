import 'dart:math' as math;

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
    int compoundsPerYear = 1,
  }) {
    if (years < 0) {
      throw ArgumentError('Yıl negatif olamaz.');
    }
    if (compoundsPerYear <= 0) {
      throw ArgumentError('Yılda bileşikleme sayısı pozitif olmalı.');
    }

    final p = _toDouble(principal);
    final r = _toRate(annualRate);
    final m = compoundsPerYear.toDouble();
    final n = years.toDouble();
    final fv = p * math.pow(1 + (r / m), m * n);
    return _toDecimal(fv);
  }

  static DecimalValue tvmSolveFutureValue({
    required int periods,
    required DecimalValue ratePercentPerPeriod,
    required DecimalValue presentValue,
    required DecimalValue paymentPerPeriod,
  }) {
    final n = periods.toDouble();
    final r = _toRate(ratePercentPerPeriod);
    final pv = _toDouble(presentValue);
    final pmt = _toDouble(paymentPerPeriod);

    final fv = r == 0
        ? -(pv + (pmt * n))
        : -((pv * math.pow(1 + r, n)) + (pmt * ((math.pow(1 + r, n) - 1) / r)));
    return _toDecimal(fv);
  }

  static DecimalValue tvmSolvePayment({
    required int periods,
    required DecimalValue ratePercentPerPeriod,
    required DecimalValue presentValue,
    required DecimalValue futureValue,
  }) {
    final n = periods.toDouble();
    final r = _toRate(ratePercentPerPeriod);
    final pv = _toDouble(presentValue);
    final fv = _toDouble(futureValue);

    final pmt = r == 0
        ? -((pv + fv) / n)
        : -((fv + (pv * math.pow(1 + r, n))) / ((math.pow(1 + r, n) - 1) / r));
    return _toDecimal(pmt);
  }

  static DecimalValue tvmSolvePresentValue({
    required int periods,
    required DecimalValue ratePercentPerPeriod,
    required DecimalValue futureValue,
    required DecimalValue paymentPerPeriod,
  }) {
    final n = periods.toDouble();
    final r = _toRate(ratePercentPerPeriod);
    final fv = _toDouble(futureValue);
    final pmt = _toDouble(paymentPerPeriod);

    final pv = r == 0
        ? -(fv + (pmt * n))
        : -((fv + (pmt * ((math.pow(1 + r, n) - 1) / r))) / math.pow(1 + r, n));
    return _toDecimal(pv);
  }

  static AmortizationResult amortization({
    required DecimalValue principal,
    required DecimalValue annualRatePercent,
    required int paymentsPerYear,
    required int totalPayments,
    required int fromPayment,
    required int toPayment,
  }) {
    final p = _toDouble(principal);
    final yearly = _toRate(annualRatePercent);
    final r = yearly / paymentsPerYear;
    final n = totalPayments.toDouble();
    final payment = r == 0 ? (p / n) : (p * r / (1 - math.pow(1 + r, -n)));

    var balance = p;
    var totalInterest = 0.0;
    var totalPrincipal = 0.0;

    for (var period = 1; period <= toPayment; period++) {
      final interest = balance * r;
      final principalPaid = payment - interest;
      balance -= principalPaid;

      if (period >= fromPayment) {
        totalInterest += interest;
        totalPrincipal += principalPaid;
      }
    }

    return AmortizationResult(
      paymentPerPeriod: _toDecimal(payment),
      totalInterest: _toDecimal(totalInterest),
      totalPrincipal: _toDecimal(totalPrincipal),
      balance: _toDecimal(balance),
    );
  }

  static DecimalValue npv({
    required DecimalValue discountRatePercent,
    required List<DecimalValue> cashFlows,
  }) {
    if (cashFlows.isEmpty) return DecimalValue.zero();
    final r = _toRate(discountRatePercent);
    var total = 0.0;
    for (var t = 0; t < cashFlows.length; t++) {
      final cf = _toDouble(cashFlows[t]);
      total += cf / math.pow(1 + r, t);
    }
    return _toDecimal(total);
  }

  static DecimalValue irrPercent({
    required List<DecimalValue> cashFlows,
    int maxIterations = 120,
    double tolerance = 1e-9,
  }) {
    if (cashFlows.length < 2) {
      throw ArgumentError('IRR için en az 2 nakit akışı gerekir.');
    }

    final flows = cashFlows.map(_toDouble).toList();
    var low = -0.9999;
    var high = 10.0;
    var fLow = _npvAtRate(flows, low);
    var fHigh = _npvAtRate(flows, high);

    var expandGuard = 0;
    while (fLow * fHigh > 0 && expandGuard < 40) {
      high *= 1.6;
      fHigh = _npvAtRate(flows, high);
      expandGuard++;
    }
    if (fLow * fHigh > 0) {
      throw ArgumentError('IRR bulunamadı.');
    }

    for (var i = 0; i < maxIterations; i++) {
      final mid = (low + high) / 2;
      final fMid = _npvAtRate(flows, mid);
      if (fMid.abs() < tolerance) {
        return _toDecimal(mid * 100);
      }
      if (fLow * fMid <= 0) {
        high = mid;
        fHigh = fMid;
      } else {
        low = mid;
        fLow = fMid;
      }
    }

    return _toDecimal(((low + high) / 2) * 100);
  }

  static DecimalValue nominalToEffective({
    required DecimalValue nominalRatePercent,
    required int compoundsPerYear,
  }) {
    if (compoundsPerYear <= 0) {
      throw ArgumentError('Yılda bileşikleme sayısı pozitif olmalı.');
    }
    final nom = _toRate(nominalRatePercent);
    final eff = math.pow(1 + (nom / compoundsPerYear), compoundsPerYear) - 1;
    return _toDecimal(eff * 100);
  }

  static DecimalValue effectiveToNominal({
    required DecimalValue effectiveRatePercent,
    required int compoundsPerYear,
  }) {
    if (compoundsPerYear <= 0) {
      throw ArgumentError('Yılda bileşikleme sayısı pozitif olmalı.');
    }
    final eff = _toRate(effectiveRatePercent);
    final nom =
        compoundsPerYear * (math.pow(1 + eff, 1 / compoundsPerYear) - 1);
    return _toDecimal(nom * 100);
  }

  static double _npvAtRate(List<double> flows, double rate) {
    var total = 0.0;
    for (var t = 0; t < flows.length; t++) {
      total += flows[t] / math.pow(1 + rate, t);
    }
    return total;
  }

  static double _toRate(DecimalValue value) => _toDouble(value) / 100;
  static double _toDouble(DecimalValue value) => double.parse(value.toString());
  static DecimalValue _toDecimal(double value) =>
      DecimalValue.parse(value.toStringAsFixed(8));
}

class AmortizationResult {
  const AmortizationResult({
    required this.paymentPerPeriod,
    required this.totalInterest,
    required this.totalPrincipal,
    required this.balance,
  });

  final DecimalValue paymentPerPeriod;
  final DecimalValue totalInterest;
  final DecimalValue totalPrincipal;
  final DecimalValue balance;
}
