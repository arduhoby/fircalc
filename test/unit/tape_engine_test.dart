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
      expect(state.pendingExpression, '15 / 3 = 5');
    });

    test('percent creates interim result and expression', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '5');
      state = engine.inputDigit(state, '0');
      state = engine.percent(state);

      expect(state.inputBuffer, '0.5');
      expect(state.pendingExpression, '50 % = 0.5');
    });

    test('vat excluded calculates gross amount with expression', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '1');
      state = engine.inputDigit(state, '0');
      state = engine.inputDigit(state, '0');
      state = engine.applyVat(
        state,
        rate: DecimalValue.parse('18'),
        mode: TapeVatMode.excluded,
      );

      expect(state.inputBuffer, '118');
      expect(state.pendingExpression, '100 + VAT(%18) = 118');
    });

    test('interim expression is preserved when adding to tape', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '1');
      state = engine.inputDigit(state, '0');
      state = engine.inputDigit(state, '0');
      state = engine.applyVat(
        state,
        rate: DecimalValue.parse('18'),
        mode: TapeVatMode.excluded,
      );
      state = engine.addSignedLine(state, TapeLineSign.plus);

      expect(state.lines.last.amount.toString(), '118');
      expect(state.lines.last.expression, '100 + VAT(%18) = 118');
    });

    test('multiply expression can be written to tape with plus sign', () {
      var state = TapeSessionState.initial();
      state = engine.inputDigit(state, '1');
      state = engine.inputDigit(state, '2');
      state = engine.startInterimOperation(
        state,
        TapePendingOperation.multiply,
      );
      state = engine.inputDigit(state, '3');
      state = engine.equals(state);
      state = engine.addSignedLine(state, TapeLineSign.plus);

      expect(state.lines.last.amount.toString(), '36');
      expect(state.lines.last.expression, '12 × 3 = 36');
    });

    test('parenthesized expression evaluates correctly', () {
      var state = TapeSessionState.initial();
      state = engine.leftParen(state);
      state = engine.inputDigit(state, '2');
      state = engine.expressionOperator(state, '+');
      state = engine.inputDigit(state, '3');
      state = engine.rightParen(state);
      state = engine.expressionOperator(state, '*');
      state = engine.inputDigit(state, '4');
      state = engine.equals(state);

      expect(state.inputBuffer, '20');
      expect(state.pendingExpression, '(2+3)*4 = 20');
    });
  });
}
