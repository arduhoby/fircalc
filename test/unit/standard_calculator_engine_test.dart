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
      expect(state.recentOperations.last, '2+3 = 5');
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

    test('expression with parentheses is evaluated with precedence', () {
      var state = StandardCalculatorState.initial();
      state = engine.leftParen(state);
      state = engine.inputDigit(state, '2');
      state = engine.setOperation(state, CalcOperator.add);
      state = engine.inputDigit(state, '3');
      state = engine.rightParen(state);
      state = engine.setOperation(state, CalcOperator.multiply);
      state = engine.inputDigit(state, '4');
      state = engine.equals(state);
      expect(state.display, '20');
    });

    test('power operation works', () {
      var state = StandardCalculatorState.initial();
      state = engine.inputDigit(state, '2');
      state = engine.power(state);
      state = engine.inputDigit(state, '3');
      state = engine.equals(state);
      expect(state.display, '8');
    });

    test('sqrt operation works', () {
      var state = StandardCalculatorState.initial();
      state = engine.sqrt(state);
      state = engine.inputDigit(state, '1');
      state = engine.inputDigit(state, '4');
      state = engine.rightParen(state);
      state = engine.equals(state);
      expect(state.display, '3.74165739');
    });

    test('nested parentheses are evaluated correctly', () {
      var state = StandardCalculatorState.initial();
      state = engine.leftParen(state);
      state = engine.inputDigit(state, '2');
      state = engine.setOperation(state, CalcOperator.add);
      state = engine.leftParen(state);
      state = engine.inputDigit(state, '3');
      state = engine.setOperation(state, CalcOperator.multiply);
      state = engine.leftParen(state);
      state = engine.inputDigit(state, '4');
      state = engine.setOperation(state, CalcOperator.add);
      state = engine.inputDigit(state, '1');
      state = engine.rightParen(state);
      state = engine.rightParen(state);
      state = engine.rightParen(state);
      state = engine.equals(state);
      expect(state.display, '17');
    });

    test('implicit multiplication between adjacent parentheses works', () {
      var state = StandardCalculatorState.initial();
      state = engine.leftParen(state);
      state = engine.inputDigit(state, '2');
      state = engine.setOperation(state, CalcOperator.add);
      state = engine.inputDigit(state, '1');
      state = engine.rightParen(state);
      state = engine.leftParen(state);
      state = engine.inputDigit(state, '3');
      state = engine.setOperation(state, CalcOperator.add);
      state = engine.inputDigit(state, '1');
      state = engine.rightParen(state);
      state = engine.equals(state);
      expect(state.display, '12');
    });
  });
}
