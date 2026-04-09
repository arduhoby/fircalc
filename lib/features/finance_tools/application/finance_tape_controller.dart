import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/types/decimal_value.dart';
import '../../calculator_tape/domain/tape_engine.dart';
import '../../calculator_tape/domain/tape_models.dart';

final financeTapeControllerProvider =
    NotifierProvider<FinanceTapeController, TapeSessionState>(
      FinanceTapeController.new,
    );

class FinanceTapeController extends Notifier<TapeSessionState> {
  final _engine = TapeEngine();

  @override
  TapeSessionState build() => TapeSessionState.initial();

  void digit(String d) => state = _engine.inputDigit(state, d);
  void decimalPoint() => state = _engine.inputDecimal(state);
  void toggleSign() => state = _engine.toggleSign(state);
  void clearEntry() => state = _engine.clearEntry(state);
  void backspace() => state = _engine.backspace(state);
  void clearAll() => state = _engine.clearAll(state);
  void percent() => state = _engine.percent(state);
  void addPlus() => state = _engine.addSignedLine(state, TapeLineSign.plus);
  void addMinus() => state = _engine.addSignedLine(state, TapeLineSign.minus);
  void startMultiply() =>
      state = _engine.startInterimOperation(
        state,
        TapePendingOperation.multiply,
      );
  void startDivide() =>
      state = _engine.startInterimOperation(
        state,
        TapePendingOperation.divide,
      );
  void equals() => state = _engine.equals(state);
  void vat({required String ratePercent, required TapeVatMode mode}) {
    state = _engine.applyVat(
      state,
      rate: DecimalValue.parse(ratePercent),
      mode: mode,
    );
  }

  void applyEffectiveFxRate({
    required String currencyLabel,
    required String rate,
  }) {
    state = _engine.applyEffectiveFxRate(
      state,
      currencyLabel: currencyLabel,
      rate: DecimalValue.parse(rate),
    );
  }

  void applyFormulaResult({
    required String expression,
    required String result,
  }) {
    state = _engine.applyFormulaResult(
      state,
      expression: expression,
      result: DecimalValue.parse(result),
    );
  }

  void leftParen() => state = _engine.leftParen(state);
  void rightParen() => state = _engine.rightParen(state);
  void power() => state = _engine.power(state);
  void sqrt() => state = _engine.sqrt(state);

  void memoryRecall(TapeMemorySlot slot) =>
      state = _engine.memoryRecall(state, slot);
  void memoryAdd(TapeMemorySlot slot) => state = _engine.memoryAdd(state, slot);
  void memorySubtract(TapeMemorySlot slot) =>
      state = _engine.memorySubtract(state, slot);
  void memoryClear(TapeMemorySlot slot) =>
      state = _engine.memoryClear(state, slot);
}
