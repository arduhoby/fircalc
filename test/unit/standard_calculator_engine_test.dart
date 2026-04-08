import 'package:flutter_test/flutter_test.dart';
import 'package:mfcalc/features/calculator_standard/domain/standard_calculator_engine.dart';
import 'package:mfcalc/features/calculator_standard/domain/standard_calculator_state.dart';

void main() {
  group('StandardCalculatorEngine', () {
    final engine = StandardCalculatorEngine();

    test('adds two integers', () {
      var state = StandardCalculatorState.initial();
      state = engine.inputDigit(state, '2');
      state = engine.setOperation(state, CalcOperator.add);
      state = engine.inputDigit(state, '3');
      state = engine.equals(state);
      expect(state.display, '5');
    });

    test('clear entry resets only current input', () {
      var state = StandardCalculatorState.initial();
      state = engine.inputDigit(state, '8');
      state = engine.setOperation(state, CalcOperator.multiply);
      state = engine.inputDigit(state, '7');
      state = engine.clearEntry(state);
      expect(state.currentInput, '0');
      expect(state.pendingOperator, CalcOperator.multiply);
    });

    test('memory store and recall', () {
      var state = StandardCalculatorState.initial();
      state = engine.inputDigit(state, '9');
      state = engine.memoryStore(state, MemorySlot.m1);
      state = engine.clearEntry(state);
      state = engine.memoryRecall(state, MemorySlot.m1);
      expect(state.display, '9');
    });
  });
}
