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
  void power() => state = _engine.power(state);
  void leftParen() => state = _engine.leftParen(state);
  void rightParen() => state = _engine.rightParen(state);
  void sqrt() => state = _engine.sqrt(state);
  void backspace() => state = _engine.backspace(state);
  void equals() => state = _engine.equals(state);
  void clear() => state = _engine.clear(state);
  void clearEntry() => state = _engine.clearEntry(state);
  void toggleSign() => state = _engine.toggleSign(state);
  void percent() => state = _engine.percent(state);
  void circleArea(double radius) =>
      state = _engine.circleArea(state, radius: radius);
  void rectangleArea({required double shortSide, required double longSide}) =>
      state = _engine.rectangleArea(
        state,
        shortSide: shortSide,
        longSide: longSide,
      );
  void quadrilateralArea(List<QuadrilateralPoint> points) =>
      state = _engine.quadrilateralArea(state, points: points);
  void latLonArea(List<LatLonPoint> points) =>
      state = _engine.latLonArea(state, points: points);
  void random(RandomGenerationRequest request) =>
      state = _engine.generateRandom(state, request: request);
  void convertUnit({
    required ConvertUnit from,
    required ConvertUnit to,
    required double value,
  }) => state = _engine.convertUnit(state, from: from, to: to, value: value);
  void electricOhmLaw({
    required ElectricOhmTarget target,
    double? voltage,
    double? current,
    double? resistance,
  }) => state = _engine.electricOhmLaw(
    state,
    target: target,
    voltage: voltage,
    current: current,
    resistance: resistance,
  );
  void electricPower({
    required ElectricPowerTarget target,
    double? power,
    double? voltage,
    double? current,
  }) => state = _engine.electricPower(
    state,
    target: target,
    power: power,
    voltage: voltage,
    current: current,
  );
  DateDifferenceResult calculateDateDifference(DateTime start, DateTime end) =>
      _engine.calculateDateDifference(start, end);
  void applyTextResult({
    required String display,
    required String historyLabel,
    String? currentInput,
  }) => state = _engine.applyTextResult(
    state,
    display: display,
    historyLabel: historyLabel,
    currentInput: currentInput,
  );

  void memoryStore(MemorySlot slot) => state = _engine.memoryStore(state, slot);
  void memoryRecall(MemorySlot slot) =>
      state = _engine.memoryRecall(state, slot);
  void memoryAdd(MemorySlot slot) => state = _engine.memoryAdd(state, slot);
  void memorySubtract(MemorySlot slot) =>
      state = _engine.memorySubtract(state, slot);
  void memoryClear(MemorySlot slot) => state = _engine.memoryClear(state, slot);
}
