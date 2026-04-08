import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/types/decimal_value.dart';
import '../../../core/utils/number_display_formatter.dart';
import '../../../core/widgets/calc_key_button.dart';
import '../../calculator_tape/application/tape_controller.dart';
import '../../calculator_tape/domain/tape_models.dart';
import '../domain/finance_calculators.dart';
import '../../market_data/application/market_quote_provider.dart';
import '../../market_data/domain/market_models.dart';
import '../../settings/application/display_settings_controller.dart';
import '../../settings/domain/display_settings.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tapeControllerProvider);
    final controller = ref.read(tapeControllerProvider.notifier);
    final settings = ref.watch(displaySettingsProvider);
    final fxRates = ref
        .watch(trackedFxRatesProvider)
        .maybeWhen(
          data: (list) => _EffectiveFxRates.fromSnapshots(list),
          orElse: _EffectiveFxRates.empty,
        );
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _FinanceDigitalPanel(
              state: state,
              locale: locale,
              settings: settings,
            ),
            const SizedBox(height: 8),
            _FinanceFormulaBar(controller: controller),
            const SizedBox(height: 8),
            _FinanceKeypad(
              controller: controller,
              settings: settings,
              fxRates: fxRates,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceFormulaBar extends StatelessWidget {
  const _FinanceFormulaBar({required this.controller});

  final TapeController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonal(
          onPressed: () async {
            final result = await _openTvmSheet(context);
            if (result == null) return;
            controller.applyFormulaResult(
              expression: result.expression,
              result: result.result.toString(),
            );
          },
          child: const Text('TVM'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final result = await _openAmortSheet(context);
            if (result == null) return;
            controller.applyFormulaResult(
              expression: result.expression,
              result: result.result.toString(),
            );
          },
          child: const Text('AMORT'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final result = await _openCashFlowSheet(context);
            if (result == null) return;
            controller.applyFormulaResult(
              expression: result.expression,
              result: result.result.toString(),
            );
          },
          child: const Text('CF'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final result = await _openRateConversionSheet(context);
            if (result == null) return;
            controller.applyFormulaResult(
              expression: result.expression,
              result: result.result.toString(),
            );
          },
          child: const Text('NOM/EFF'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final result = await _openQuickPmtSheet(context);
            if (result == null) return;
            controller.applyFormulaResult(
              expression: result.expression,
              result: result.result.toString(),
            );
          },
          child: const Text('PMT'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final result = await _openSimpleInterestSheet(context);
            if (result == null) return;
            controller.applyFormulaResult(
              expression: result.expression,
              result: result.result.toString(),
            );
          },
          child: const Text('S. FAİZ'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            final result = await _openCompoundInterestSheet(context);
            if (result == null) return;
            controller.applyFormulaResult(
              expression: result.expression,
              result: result.result.toString(),
            );
          },
          child: const Text('B. FAİZ'),
        ),
      ],
    );
  }

  Future<_FormulaResult?> _openTvmSheet(BuildContext context) async {
    final nCtrl = TextEditingController(text: '12');
    final iCtrl = TextEditingController(text: '2.5');
    final pvCtrl = TextEditingController(text: '10000');
    final pmtCtrl = TextEditingController(text: '0');
    final fvCtrl = TextEditingController(text: '0');
    var solve = _TvmSolve.fv;

    return showModalBottomSheet<_FormulaResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<_TvmSolve>(
                  value: solve,
                  items: const [
                    DropdownMenuItem(
                      value: _TvmSolve.fv,
                      child: Text('Çöz: FV'),
                    ),
                    DropdownMenuItem(
                      value: _TvmSolve.pmt,
                      child: Text('Çöz: PMT'),
                    ),
                    DropdownMenuItem(
                      value: _TvmSolve.pv,
                      child: Text('Çöz: PV'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => solve = v);
                  },
                ),
                _input('N', nCtrl, number: true),
                _input('I/Y (Dönem %)', iCtrl, number: true),
                _input('PV', pvCtrl, number: true),
                _input('PMT', pmtCtrl, number: true),
                _input('FV', fvCtrl, number: true),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    try {
                      final n = int.parse(nCtrl.text.trim());
                      final i = DecimalValue.parse(iCtrl.text.trim());
                      final pv = DecimalValue.parse(pvCtrl.text.trim());
                      final pmt = DecimalValue.parse(pmtCtrl.text.trim());
                      final fv = DecimalValue.parse(fvCtrl.text.trim());

                      final result = switch (solve) {
                        _TvmSolve.fv => FinanceCalculators.tvmSolveFutureValue(
                          periods: n,
                          ratePercentPerPeriod: i,
                          presentValue: pv,
                          paymentPerPeriod: pmt,
                        ),
                        _TvmSolve.pmt => FinanceCalculators.tvmSolvePayment(
                          periods: n,
                          ratePercentPerPeriod: i,
                          presentValue: pv,
                          futureValue: fv,
                        ),
                        _TvmSolve.pv => FinanceCalculators.tvmSolvePresentValue(
                          periods: n,
                          ratePercentPerPeriod: i,
                          futureValue: fv,
                          paymentPerPeriod: pmt,
                        ),
                      };
                      final solved = switch (solve) {
                        _TvmSolve.fv => 'FV',
                        _TvmSolve.pmt => 'PMT',
                        _TvmSolve.pv => 'PV',
                      };
                      Navigator.pop(
                        context,
                        _FormulaResult(
                          expression:
                              'TVM $solved (N=$n I/Y=${i.toString()} PV=${pv.toString()} PMT=${pmt.toString()} FV=${fv.toString()})',
                          result: result,
                        ),
                      );
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Girdi hatası')),
                      );
                    }
                  },
                  child: const Text('Hesapla'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_FormulaResult?> _openAmortSheet(BuildContext context) async {
    final principalCtrl = TextEditingController(text: '100000');
    final annualCtrl = TextEditingController(text: '36');
    final ppyCtrl = TextEditingController(text: '12');
    final nCtrl = TextEditingController(text: '24');
    final p1Ctrl = TextEditingController(text: '1');
    final p2Ctrl = TextEditingController(text: '12');

    return showModalBottomSheet<_FormulaResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('Anapara', principalCtrl, number: true),
              _input('Yıllık Faiz %', annualCtrl, number: true),
              _input('Yılda Ödeme', ppyCtrl, number: true),
              _input('Toplam Dönem', nCtrl, number: true),
              _input('P1', p1Ctrl, number: true),
              _input('P2', p2Ctrl, number: true),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  try {
                    final result = FinanceCalculators.amortization(
                      principal: DecimalValue.parse(principalCtrl.text.trim()),
                      annualRatePercent: DecimalValue.parse(
                        annualCtrl.text.trim(),
                      ),
                      paymentsPerYear: int.parse(ppyCtrl.text.trim()),
                      totalPayments: int.parse(nCtrl.text.trim()),
                      fromPayment: int.parse(p1Ctrl.text.trim()),
                      toPayment: int.parse(p2Ctrl.text.trim()),
                    );
                    Navigator.pop(
                      context,
                      _FormulaResult(
                        expression:
                            'AMORT INT=${result.totalInterest.toString()} PRN=${result.totalPrincipal.toString()}',
                        result: result.balance,
                      ),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Girdi hatası')),
                    );
                  }
                },
                child: const Text('Hesapla'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_FormulaResult?> _openCashFlowSheet(BuildContext context) async {
    final rateCtrl = TextEditingController(text: '25');
    final cfCtrl = TextEditingController(text: '-100000, 30000, 35000, 40000');
    var mode = _CashFlowSolve.npv;

    return showModalBottomSheet<_FormulaResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<_CashFlowSolve>(
                  value: mode,
                  items: const [
                    DropdownMenuItem(
                      value: _CashFlowSolve.npv,
                      child: Text('Çöz: NPV'),
                    ),
                    DropdownMenuItem(
                      value: _CashFlowSolve.irr,
                      child: Text('Çöz: IRR'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => mode = v);
                  },
                ),
                if (mode == _CashFlowSolve.npv)
                  _input('İskonto %', rateCtrl, number: true),
                _input('Nakit Akışları (virgül ile)', cfCtrl, number: false),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    try {
                      final flows = cfCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .map(DecimalValue.parse)
                          .toList();
                      if (flows.isEmpty) {
                        throw ArgumentError('Nakit akışı boş.');
                      }

                      if (mode == _CashFlowSolve.npv) {
                        final rate = DecimalValue.parse(rateCtrl.text.trim());
                        final result = FinanceCalculators.npv(
                          discountRatePercent: rate,
                          cashFlows: flows,
                        );
                        Navigator.pop(
                          context,
                          _FormulaResult(
                            expression: 'NPV(rate=${rate.toString()}%)',
                            result: result,
                          ),
                        );
                        return;
                      }

                      final result = FinanceCalculators.irrPercent(
                        cashFlows: flows,
                      );
                      Navigator.pop(
                        context,
                        _FormulaResult(expression: 'IRR%', result: result),
                      );
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Girdi hatası')),
                      );
                    }
                  },
                  child: const Text('Hesapla'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_FormulaResult?> _openRateConversionSheet(BuildContext context) async {
    final rateCtrl = TextEditingController(text: '36');
    final mCtrl = TextEditingController(text: '12');
    var mode = _RateSolve.nomToEff;

    return showModalBottomSheet<_FormulaResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<_RateSolve>(
                  value: mode,
                  items: const [
                    DropdownMenuItem(
                      value: _RateSolve.nomToEff,
                      child: Text('NOM -> EFF'),
                    ),
                    DropdownMenuItem(
                      value: _RateSolve.effToNom,
                      child: Text('EFF -> NOM'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => mode = v);
                  },
                ),
                _input('Faiz %', rateCtrl, number: true),
                _input('Yılda bileşikleme (m)', mCtrl, number: true),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    try {
                      final rate = DecimalValue.parse(rateCtrl.text.trim());
                      final m = int.parse(mCtrl.text.trim());
                      final result = mode == _RateSolve.nomToEff
                          ? FinanceCalculators.nominalToEffective(
                              nominalRatePercent: rate,
                              compoundsPerYear: m,
                            )
                          : FinanceCalculators.effectiveToNominal(
                              effectiveRatePercent: rate,
                              compoundsPerYear: m,
                            );
                      Navigator.pop(
                        context,
                        _FormulaResult(
                          expression: mode == _RateSolve.nomToEff
                              ? 'EFF%(NOM=${rate.toString()} m=$m)'
                              : 'NOM%(EFF=${rate.toString()} m=$m)',
                          result: result,
                        ),
                      );
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Girdi hatası')),
                      );
                    }
                  },
                  child: const Text('Hesapla'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_FormulaResult?> _openSimpleInterestSheet(BuildContext context) async {
    final principalCtrl = TextEditingController(text: '100000');
    final annualCtrl = TextEditingController(text: '36');
    final yearsCtrl = TextEditingController(text: '3');

    return showModalBottomSheet<_FormulaResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('Anapara', principalCtrl, number: true),
              _input('Yıllık faiz %', annualCtrl, number: true),
              _input('Yıl', yearsCtrl, number: true),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  try {
                    final principal = DecimalValue.parse(
                      principalCtrl.text.trim(),
                    );
                    final annual = DecimalValue.parse(annualCtrl.text.trim());
                    final years = int.parse(yearsCtrl.text.trim());
                    final result = FinanceCalculators.simpleInterest(
                      principal: principal,
                      annualRate: annual,
                      years: years,
                    );
                    final months = years * 12;
                    Navigator.pop(
                      context,
                      _FormulaResult(
                        expression:
                            'Basit Faiz | AnaPara=${principal.toString()} | Faiz%=${annual.toString()} | Vade=${months}ay',
                        result: result,
                      ),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Girdi hatası')),
                    );
                  }
                },
                child: const Text('Hesapla'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_FormulaResult?> _openCompoundInterestSheet(
    BuildContext context,
  ) async {
    final principalCtrl = TextEditingController(text: '100000');
    final annualCtrl = TextEditingController(text: '36');
    final yearsCtrl = TextEditingController(text: '2');
    final mCtrl = TextEditingController(text: '12');

    return showModalBottomSheet<_FormulaResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('Anapara (P)', principalCtrl, number: true),
              _input('Yıllık faiz % (r)', annualCtrl, number: true),
              _input('Yıl (y)', yearsCtrl, number: true),
              _input('Yılda bileşikleme (m)', mCtrl, number: true),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  try {
                    final principal = DecimalValue.parse(
                      principalCtrl.text.trim(),
                    );
                    final annual = DecimalValue.parse(annualCtrl.text.trim());
                    final years = int.parse(yearsCtrl.text.trim());
                    final m = int.parse(mCtrl.text.trim());
                    final result = FinanceCalculators.compoundInterest(
                      principal: principal,
                      annualRate: annual,
                      years: years,
                      compoundsPerYear: m,
                    );
                    final months = years * 12;
                    Navigator.pop(
                      context,
                      _FormulaResult(
                        expression:
                            'Birleşik Faiz | AnaPara=${principal.toString()} | Faiz%=${annual.toString()} | Vade=${months}ay | m=$m',
                        result: result,
                      ),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Girdi hatası')),
                    );
                  }
                },
                child: const Text('Hesapla'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_FormulaResult?> _openQuickPmtSheet(BuildContext context) async {
    final nCtrl = TextEditingController(text: '24');
    final iCtrl = TextEditingController(text: '2.5');
    final pvCtrl = TextEditingController(text: '100000');

    return showModalBottomSheet<_FormulaResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _input('N', nCtrl, number: true),
              _input('I/Y (Dönem %)', iCtrl, number: true),
              _input('PV', pvCtrl, number: true),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  try {
                    final n = int.parse(nCtrl.text.trim());
                    final i = DecimalValue.parse(iCtrl.text.trim());
                    final pv = DecimalValue.parse(pvCtrl.text.trim());
                    final result = FinanceCalculators.tvmSolvePayment(
                      periods: n,
                      ratePercentPerPeriod: i,
                      presentValue: pv,
                      futureValue: DecimalValue.zero(),
                    );
                    Navigator.pop(
                      context,
                      _FormulaResult(
                        expression:
                            'PMT(N=$n I/Y=${i.toString()} PV=${pv.toString()})',
                        result: result,
                      ),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Girdi hatası')),
                    );
                  }
                },
                child: const Text('Hesapla'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    required bool number,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

enum _TvmSolve { fv, pmt, pv }

enum _CashFlowSolve { npv, irr }

enum _RateSolve { nomToEff, effToNom }

class _FormulaResult {
  const _FormulaResult({required this.expression, required this.result});

  final String expression;
  final DecimalValue result;
}

class _FinanceDigitalPanel extends StatelessWidget {
  const _FinanceDigitalPanel({
    required this.state,
    required this.locale,
    required this.settings,
  });

  final TapeSessionState state;
  final String locale;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    const visibleLineCount = 7;
    const historyLineHeight = 22.0;
    final lines = state.lines.reversed
        .take(visibleLineCount)
        .toList()
        .reversed
        .toList();
    final liveExpression = _buildLiveExpression();
    final pendingExpression = _toDisplayExpression(
      state.pendingExpression ?? '',
    );
    final headerExpression = pendingExpression.isNotEmpty
        ? pendingExpression
        : liveExpression;
    final current = NumberDisplayFormatter.format(
      raw: state.inputBuffer,
      locale: locale,
      settings: settings,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF253322),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A5A45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(visibleLineCount, (i) {
            final row = i < lines.length ? lines[i] : null;
            if (row == null) {
              return const SizedBox(height: historyLineHeight);
            }
            final amount = NumberDisplayFormatter.format(
              raw: row.amount.toString(),
              locale: locale,
              settings: settings,
            );
            final left = row.expression ?? '';
            return SizedBox(
              height: historyLineHeight,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8BD13A),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(
                      color: Color(0xFFB8FF4A),
                      fontSize: 15,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (headerExpression.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                headerExpression,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFF8BD13A), fontSize: 13),
              ),
            ),
          const Divider(height: 10, color: Color(0x664A5A45)),
          Text(
            current,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFFB8FF4A),
              fontWeight: FontWeight.w700,
              fontSize: 28,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _buildLiveExpression() {
    final raw =
        '${state.expressionBuffer}${state.inputBuffer == '0' ? '' : state.inputBuffer}';
    if (raw.isEmpty) return '';
    return _toDisplayExpression(raw);
  }

  String _toDisplayExpression(String raw) {
    return raw
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('sqrt', '√');
  }
}

class _FinanceKeypad extends StatelessWidget {
  const _FinanceKeypad({
    required this.controller,
    required this.settings,
    required this.fxRates,
  });

  final TapeController controller;
  final DisplaySettings settings;
  final _EffectiveFxRates fxRates;

  @override
  Widget build(BuildContext context) {
    final leftAuxLabel = settings.tapeAuxLeft.label;
    final rightAuxLabel = settings.tapeAuxRight.label;
    final specs = [
      const _KeySpec(
        label: 'C',
        row: 0,
        col: 0,
        backgroundColor: Color(0xFFB00020),
      ),
      const _KeySpec(label: '(', row: 0, col: 1),
      const _KeySpec(label: ')', row: 0, col: 2),
      const _KeySpec(label: '√', row: 0, col: 3),
      const _KeySpec(label: '^', row: 0, col: 4),
      const _KeySpec(label: '%', row: 1, col: 0),
      const _KeySpec(label: 'VAT', row: 1, col: 1),
      _KeySpec(label: leftAuxLabel, row: 1, col: 2),
      _KeySpec(label: rightAuxLabel, row: 1, col: 3),
      const _KeySpec(label: '<', row: 1, col: 4),
      const _KeySpec(label: '7', row: 2, col: 0),
      const _KeySpec(label: '8', row: 2, col: 1),
      const _KeySpec(label: '9', row: 2, col: 2),
      const _KeySpec(label: '÷', row: 2, col: 3),
      const _KeySpec(label: 'CE', row: 2, col: 4),
      const _KeySpec(label: '4', row: 3, col: 0),
      const _KeySpec(label: '5', row: 3, col: 1),
      const _KeySpec(label: '6', row: 3, col: 2),
      const _KeySpec(label: '×', row: 3, col: 3),
      const _KeySpec(label: '1', row: 4, col: 0),
      const _KeySpec(label: '2', row: 4, col: 1),
      const _KeySpec(label: '3', row: 4, col: 2),
      const _KeySpec(label: '-', row: 4, col: 3),
      const _KeySpec(label: '+', row: 3, col: 4, rowSpan: 2),
      const _KeySpec(label: '0', row: 5, col: 0),
      const _KeySpec(label: '000', row: 5, col: 1),
      const _KeySpec(label: ',', row: 5, col: 2),
      const _KeySpec(label: '=', row: 5, col: 3, colSpan: 2),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 5;
        const rows = 6;
        const gap = 8.0;
        final keyHeight = settings.tapeKeyHeight.toDouble();
        final keyWidth = (constraints.maxWidth - ((cols - 1) * gap)) / cols;
        final totalHeight = (rows * keyHeight) + ((rows - 1) * gap);

        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: specs.map((spec) {
              final left = spec.col * (keyWidth + gap);
              final top = spec.row * (keyHeight + gap);
              final width =
                  (spec.colSpan * keyWidth) + ((spec.colSpan - 1) * gap);
              final height =
                  (spec.rowSpan * keyHeight) + ((spec.rowSpan - 1) * gap);
              final isOperator = [
                '÷',
                '×',
                '-',
                '+',
                '%',
                'VAT',
                '^',
                '√',
              ].contains(spec.label);
              final isEquals = spec.label == '=';

              return Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: CalcKeyButton(
                  label: spec.label,
                  isOperator: isOperator,
                  isEquals: isEquals,
                  backgroundColor: spec.backgroundColor,
                  foregroundColor: spec.backgroundColor == null
                      ? null
                      : Colors.white,
                  onTap: () => unawaited(_tap(context, spec.label)),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _tap(BuildContext context, String key) async {
    if (settings.tapeKeySoundEnabled) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
    if (key == settings.tapeAuxLeft.label ||
        key == settings.tapeAuxRight.label) {
      await _handleAuxCurrency(context, key);
      return;
    }
    switch (key) {
      case 'C':
        controller.clearAll();
        return;
      case '(':
        controller.leftParen();
        return;
      case ')':
        controller.rightParen();
        return;
      case '^':
        controller.power();
        return;
      case '√':
        controller.sqrt();
        return;
      case 'CE':
        controller.clearEntry();
        return;
      case '<':
        controller.backspace();
        return;
      case 'MR':
        controller.memoryRecall(TapeMemorySlot.m1);
        return;
      case 'M+':
        controller.memoryAdd(TapeMemorySlot.m1);
        return;
      case 'M-':
        controller.memorySubtract(TapeMemorySlot.m1);
        return;
      case 'MC':
        controller.memoryClear(TapeMemorySlot.m1);
        return;
      case '%':
        controller.percent();
        return;
      case 'VAT':
        final mode = await showCupertinoModalPopup<TapeVatMode>(
          context: context,
          builder: (context) => CupertinoActionSheet(
            title: Text('KDV %${settings.vatRatePercent}'),
            message: const Text('Girilen tutar KDV dahil mi, hariç mi?'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, TapeVatMode.included),
                child: const Text('Dahil'),
              ),
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, TapeVatMode.excluded),
                child: const Text('Hariç'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
          ),
        );
        if (mode == null) return;
        controller.vat(
          ratePercent: settings.vatRatePercent.toString(),
          mode: mode,
        );
        return;
      case '÷':
        controller.startDivide();
        return;
      case '×':
        controller.startMultiply();
        return;
      case '-':
        controller.addMinus();
        return;
      case '+':
        controller.addPlus();
        return;
      case '=':
        controller.equals();
        return;
      case ',':
        controller.decimalPoint();
        return;
      default:
        controller.digit(key);
        return;
    }
  }

  Future<void> _handleAuxCurrency(BuildContext context, String key) async {
    final currency = switch (key) {
      r'$' => 'USD',
      'E' => 'EUR',
      '&' => 'GBP',
      _ => null,
    };
    if (currency == null) return;

    final rate = switch (currency) {
      'USD' => fxRates.usd,
      'EUR' => fxRates.eur,
      'GBP' => fxRates.gbp,
      _ => null,
    };

    if (rate == null) return;
    controller.applyEffectiveFxRate(
      currencyLabel: currency,
      rate: rate.toString(),
    );
  }
}

class _KeySpec {
  const _KeySpec({
    required this.label,
    required this.row,
    required this.col,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.backgroundColor,
  });

  final String label;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
  final Color? backgroundColor;
}

class _EffectiveFxRates {
  const _EffectiveFxRates({
    required this.usd,
    required this.eur,
    required this.gbp,
  });

  final DecimalValue? usd;
  final DecimalValue? eur;
  final DecimalValue? gbp;

  factory _EffectiveFxRates.empty() => _EffectiveFxRates(
    usd: DecimalValue.parse('38.3400'),
    eur: DecimalValue.parse('41.2400'),
    gbp: DecimalValue.parse('48.2700'),
  );

  factory _EffectiveFxRates.fromSnapshots(List<FxRateSnapshot> snapshots) {
    DecimalValue? pick(String code) {
      for (final s in snapshots) {
        if (s.kind != FxRateKind.effective) continue;
        if (s.currency.code == code) return s.sell;
      }
      return null;
    }

    return _EffectiveFxRates(
      usd: pick('USD') ?? DecimalValue.parse('38.3400'),
      eur: pick('EUR') ?? DecimalValue.parse('41.2400'),
      gbp: pick('GBP') ?? DecimalValue.parse('48.2700'),
    );
  }
}
