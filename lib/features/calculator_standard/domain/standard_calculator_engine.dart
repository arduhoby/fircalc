import '../../../core/types/decimal_value.dart';
import 'standard_calculator_state.dart';

class StandardCalculatorEngine {
  StandardCalculatorState inputDigit(
    StandardCalculatorState state,
    String digit,
  ) {
    final nextInput = state.shouldResetInput
        ? digit
        : (state.currentInput == '0' ? digit : '${state.currentInput}$digit');

    return state.copyWith(
      currentInput: nextInput,
      display: nextInput,
      shouldResetInput: false,
    );
  }

  StandardCalculatorState inputDecimalPoint(StandardCalculatorState state) {
    final base = state.shouldResetInput ? '0' : state.currentInput;
    if (base.contains('.')) {
      return state;
    }
    final nextInput = '$base.';
    return state.copyWith(
      currentInput: nextInput,
      display: nextInput,
      shouldResetInput: false,
    );
  }

  StandardCalculatorState toggleSign(StandardCalculatorState state) {
    final current = DecimalValue.parse(state.currentInput);
    final next = current.negated().toString();
    return state.copyWith(currentInput: next, display: next);
  }

  StandardCalculatorState clear(StandardCalculatorState state) {
    return state.copyWith(
      display: '0',
      currentInput: '0',
      accumulator: DecimalValue.zero(),
      clearPendingOperator: true,
      shouldResetInput: false,
    );
  }

  StandardCalculatorState clearEntry(StandardCalculatorState state) {
    return state.copyWith(
      display: '0',
      currentInput: '0',
      shouldResetInput: false,
    );
  }

  StandardCalculatorState setOperation(
    StandardCalculatorState state,
    CalcOperator op,
  ) {
    final operand = DecimalValue.parse(state.currentInput);

    if (state.pendingOperator == null) {
      return state.copyWith(
        accumulator: operand,
        pendingOperator: op,
        shouldResetInput: true,
      );
    }

    final evaluated = _apply(
      state.accumulator,
      operand,
      state.pendingOperator!,
    );
    return state.copyWith(
      accumulator: evaluated,
      display: evaluated.toString(),
      currentInput: evaluated.toString(),
      pendingOperator: op,
      shouldResetInput: true,
    );
  }

  StandardCalculatorState equals(StandardCalculatorState state) {
    final operator = state.pendingOperator;
    if (operator == null) {
      return state;
    }
    final operand = DecimalValue.parse(state.currentInput);
    final result = _apply(state.accumulator, operand, operator);
    return state.copyWith(
      accumulator: result,
      currentInput: result.toString(),
      display: result.toString(),
      clearPendingOperator: true,
      shouldResetInput: true,
    );
  }

  StandardCalculatorState percent(StandardCalculatorState state) {
    final current = DecimalValue.parse(state.currentInput);
    final percent = DecimalValue.parse('1').percentOf(current);
    return state.copyWith(
      currentInput: percent.toString(),
      display: percent.toString(),
    );
  }

  StandardCalculatorState memoryStore(
    StandardCalculatorState state,
    MemorySlot slot,
  ) {
    final nextMemories = Map<MemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = DecimalValue.parse(state.currentInput);
    return state.copyWith(memories: nextMemories);
  }

  StandardCalculatorState memoryClear(
    StandardCalculatorState state,
    MemorySlot slot,
  ) {
    final nextMemories = Map<MemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = null;
    return state.copyWith(memories: nextMemories);
  }

  StandardCalculatorState memoryAdd(
    StandardCalculatorState state,
    MemorySlot slot,
  ) {
    final memory = state.memories[slot] ?? DecimalValue.zero();
    final current = DecimalValue.parse(state.currentInput);
    final nextMemories = Map<MemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = memory.plus(current);
    return state.copyWith(memories: nextMemories);
  }

  StandardCalculatorState memorySubtract(
    StandardCalculatorState state,
    MemorySlot slot,
  ) {
    final memory = state.memories[slot] ?? DecimalValue.zero();
    final current = DecimalValue.parse(state.currentInput);
    final nextMemories = Map<MemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = memory.minus(current);
    return state.copyWith(memories: nextMemories);
  }

  StandardCalculatorState memoryRecall(
    StandardCalculatorState state,
    MemorySlot slot,
  ) {
    final memory = state.memories[slot];
    if (memory == null) return state;
    return state.copyWith(
      currentInput: memory.toString(),
      display: memory.toString(),
      shouldResetInput: true,
    );
  }

  DecimalValue _apply(DecimalValue left, DecimalValue right, CalcOperator op) {
    return switch (op) {
      CalcOperator.add => left.plus(right),
      CalcOperator.subtract => left.minus(right),
      CalcOperator.multiply => left.times(right),
      CalcOperator.divide => left.dividedBy(right),
    };
  }
}
