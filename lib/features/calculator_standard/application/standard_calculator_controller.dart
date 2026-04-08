import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/standard_calculator_engine.dart';
import '../domain/standard_calculator_state.dart';

final standardCalculatorControllerProvider =
    NotifierProvider<StandardCalculatorController, StandardCalculatorState>(
      StandardCalculatorController.new,
    );

class StandardCalculatorController extends Notifier<StandardCalculatorState> {
  final _engine = StandardCalculatorEngine();

  @override
  StandardCalculatorState build() => StandardCalculatorState.initial();

  void digit(String d) => state = _engine.inputDigit(state, d);
  void decimalPoint() => state = _engine.inputDecimalPoint(state);
  void operation(CalcOperator op) => state = _engine.setOperation(state, op);
  void equals() => state = _engine.equals(state);
  void clear() => state = _engine.clear(state);
  void clearEntry() => state = _engine.clearEntry(state);
  void toggleSign() => state = _engine.toggleSign(state);
  void percent() => state = _engine.percent(state);

  void memoryStore(MemorySlot slot) => state = _engine.memoryStore(state, slot);
  void memoryRecall(MemorySlot slot) =>
      state = _engine.memoryRecall(state, slot);
  void memoryAdd(MemorySlot slot) => state = _engine.memoryAdd(state, slot);
  void memorySubtract(MemorySlot slot) =>
      state = _engine.memorySubtract(state, slot);
  void memoryClear(MemorySlot slot) => state = _engine.memoryClear(state, slot);
}
