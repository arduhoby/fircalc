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

    test('circle area works', () {
      var state = StandardCalculatorState.initial();
      state = engine.circleArea(state, radius: 3);
      expect(state.display, '28.27433388');
    });

    test('quadrilateral area works from four points', () {
      var state = StandardCalculatorState.initial();
      state = engine.quadrilateralArea(
        state,
        points: const [
          QuadrilateralPoint(x: 0, y: 0),
          QuadrilateralPoint(x: 4, y: 0),
          QuadrilateralPoint(x: 4, y: 3),
          QuadrilateralPoint(x: 0, y: 3),
        ],
      );
      expect(state.display, '12');
    });

    test('rectangle area works', () {
      var state = StandardCalculatorState.initial();
      state = engine.rectangleArea(state, shortSide: 4, longSide: 7);
      expect(state.display, '28');
    });

    test('lat lon polygon area works', () {
      var state = StandardCalculatorState.initial();
      state = engine.latLonArea(
        state,
        points: const [
          LatLonPoint(latitude: 41.0, longitude: 29.0),
          LatLonPoint(latitude: 41.0, longitude: 29.001),
          LatLonPoint(latitude: 41.001, longitude: 29.001),
          LatLonPoint(latitude: 41.001, longitude: 29.0),
        ],
      );
      final value = double.parse(state.display);
      expect(value, greaterThan(9000));
      expect(value, lessThan(10000));
    });

    test('random integer generation is unique', () {
      var state = StandardCalculatorState.initial();
      state = engine.generateRandom(
        state,
        request: const RandomGenerationRequest(
          min: 1,
          max: 5,
          count: 5,
          step: 1,
          allowFloat: false,
          decimalDigits: 0,
        ),
      );

      final values = state.display.split(', ');
      expect(values.length, 5);
      expect(values.toSet().length, 5);
    });

    test('random integer generation respects step', () {
      var state = StandardCalculatorState.initial();
      state = engine.generateRandom(
        state,
        request: const RandomGenerationRequest(
          min: 0,
          max: 10,
          count: 3,
          step: 2,
          allowFloat: false,
          decimalDigits: 0,
        ),
      );

      final values = state.display.split(', ').map(int.parse).toList();
      for (final value in values) {
        expect(value % 2, 0);
      }
    });

    test('unit conversion works for length', () {
      var state = StandardCalculatorState.initial();
      state = engine.convertUnit(
        state,
        from: convertUnits.firstWhere((unit) => unit.id == 'km'),
        to: convertUnits.firstWhere((unit) => unit.id == 'm'),
        value: 1.5,
      );
      expect(state.display, '1500');
    });

    test('ohm law computes voltage', () {
      var state = StandardCalculatorState.initial();
      state = engine.electricOhmLaw(
        state,
        target: ElectricOhmTarget.voltage,
        current: 2,
        resistance: 5,
      );
      expect(state.display, '10');
    });

    test('ohm law computes current', () {
      var state = StandardCalculatorState.initial();
      state = engine.electricOhmLaw(
        state,
        target: ElectricOhmTarget.current,
        voltage: 12,
        resistance: 4,
      );
      expect(state.display, '3');
    });

    test('electric power computes power', () {
      var state = StandardCalculatorState.initial();
      state = engine.electricPower(
        state,
        target: ElectricPowerTarget.power,
        voltage: 220,
        current: 2,
      );
      expect(state.display, '440');
    });

    test('date difference computes totals', () {
      final result = engine.calculateDateDifference(
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 11),
      );
      expect(result.totalDays, 10);
      expect(result.totalHours, 240);
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
