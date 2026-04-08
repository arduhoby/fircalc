import 'package:flutter_test/flutter_test.dart';
import 'package:mfcalc/core/types/decimal_value.dart';
import 'package:mfcalc/features/calculator_tape/domain/tape_engine.dart';
import 'package:mfcalc/features/calculator_tape/domain/tape_models.dart';

void main() {
  group('TapeEngine', () {
    final engine = TapeEngine();

    test('first equals creates subtotal line', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '1');
      state = engine.inputDigit(state, '0');
      state = engine.addSignedLine(state, TapeLineSign.plus);
      state = engine.equals(state);

      expect(state.lines.last.kind, TapeLineKind.subtotal);
      expect(state.lines.last.amount.toString(), '10');
    });

    test('second equals creates grand total line', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '2');
      state = engine.inputDigit(state, '5');
      state = engine.addSignedLine(state, TapeLineSign.plus);
      state = engine.equals(state);
      state = engine.equals(state);

      expect(state.lines.last.kind, TapeLineKind.grandTotal);
      expect(state.cycle, 2);
    });

    test('interim result can be appended with sign', () {
      var state = TapeSessionState.initial();
      final interim = engine.multiply(
        DecimalValue.parse('25'),
        DecimalValue.parse('18'),
      );
      state = engine.setInterimResult(state, interim);
      state = engine.addInterimResultToTape(state, TapeLineSign.plus);

      expect(state.lines.last.amount.toString(), '450');
      expect(state.lines.last.sign, TapeLineSign.plus);
      expect(state.lastInterimResult, isNull);
    });

    test(
      'interim multiply uses equals and does not write tape line directly',
      () {
        var state = TapeSessionState.initial();
        state = engine.inputDigit(state, '2');
        state = engine.inputDigit(state, '5');
        state = engine.startInterimOperation(
          state,
          TapePendingOperation.multiply,
        );
        state = engine.inputDigit(state, '1');
        state = engine.inputDigit(state, '8');
        state = engine.equals(state);

        expect(state.lastInterimResult?.toString(), '450');
        expect(state.lines, isEmpty);
        expect(state.inputBuffer, '450');
      },
    );

    test('division writes interim expression in expected form', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '1');
      state = engine.inputDigit(state, '5');
      state = engine.startInterimOperation(state, TapePendingOperation.divide);
      state = engine.inputDigit(state, '3');
      state = engine.equals(state);

      expect(state.inputBuffer, '5');
      expect(state.pendingExpression, '15 / 3 =');
    });

    test('percent creates interim result and expression', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '5');
      state = engine.inputDigit(state, '0');
      state = engine.percent(state);

      expect(state.inputBuffer, '0.5');
      expect(state.pendingExpression, '50 % =');
    });
  });
}
