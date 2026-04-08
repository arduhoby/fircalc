import '../../../core/types/decimal_value.dart';
import 'tape_models.dart';

class TapeEngine {
  TapeSessionState inputDigit(TapeSessionState state, String digit) {
    final next = state.inputBuffer == '0'
        ? digit
        : '${state.inputBuffer}$digit';
    return state.copyWith(inputBuffer: next);
  }

  TapeSessionState toggleSign(TapeSessionState state) {
    final current = DecimalValue.parse(state.inputBuffer);
    return state.copyWith(inputBuffer: current.negated().toString());
  }

  TapeSessionState inputDecimal(TapeSessionState state) {
    if (state.inputBuffer.contains('.')) return state;
    return state.copyWith(inputBuffer: '${state.inputBuffer}.');
  }

  TapeSessionState clearEntry(TapeSessionState state) =>
      state.copyWith(inputBuffer: '0');

  TapeSessionState clearAll(TapeSessionState state) =>
      TapeSessionState.initial().copyWith(memories: state.memories);

  TapeSessionState addSignedLine(TapeSessionState state, TapeLineSign sign) {
    final amount = DecimalValue.parse(state.inputBuffer);
    final line = TapeLine(
      index: state.lines.length + 1,
      sign: sign,
      amount: amount,
      kind: TapeLineKind.normal,
      createdAt: DateTime.now(),
    );
    return state.copyWith(
      lines: [...state.lines, line],
      inputBuffer: '0',
      equalsCount: 0,
      clearInterimResult: true,
      clearPendingLeftOperand: true,
      clearPendingOperation: true,
      clearPendingExpression: true,
    );
  }

  TapeSessionState startInterimOperation(
    TapeSessionState state,
    TapePendingOperation operation,
  ) {
    final left = DecimalValue.parse(state.inputBuffer);
    final op = operation == TapePendingOperation.multiply ? '×' : '/';
    return state.copyWith(
      pendingOperation: operation,
      pendingLeftOperand: left,
      inputBuffer: '0',
      equalsCount: 0,
      clearInterimResult: true,
      pendingExpression: '${left.toString()} $op ',
    );
  }

  TapeSessionState percent(TapeSessionState state) {
    final value = DecimalValue.parse(state.inputBuffer);
    final result = value.dividedBy(DecimalValue.parse('100'));
    return state.copyWith(
      inputBuffer: result.toString(),
      lastInterimResult: result,
      pendingExpression: '${value.toString()} % =',
      clearPendingLeftOperand: true,
      clearPendingOperation: true,
    );
  }

  TapeSessionState equals(TapeSessionState state) {
    if (state.pendingOperation != null && state.pendingLeftOperand != null) {
      final right = DecimalValue.parse(state.inputBuffer);
      DecimalValue result;
      try {
        result = switch (state.pendingOperation!) {
          TapePendingOperation.multiply => multiply(
            state.pendingLeftOperand!,
            right,
          ),
          TapePendingOperation.divide => divide(
            state.pendingLeftOperand!,
            right,
          ),
        };
      } catch (_) {
        final opErr = state.pendingOperation == TapePendingOperation.multiply
            ? '×'
            : '/';
        return state.copyWith(
          pendingExpression:
              '${state.pendingLeftOperand} $opErr ${right.toString()} = Hata',
          clearPendingOperation: true,
          clearPendingLeftOperand: true,
        );
      }
      final op = state.pendingOperation == TapePendingOperation.multiply
          ? '×'
          : '/';
      return state.copyWith(
        inputBuffer: result.toString(),
        lastInterimResult: result,
        pendingExpression:
            '${state.pendingLeftOperand} $op ${right.toString()} =',
        clearPendingOperation: true,
        clearPendingLeftOperand: true,
      );
    }

    final subtotal = _computeTotal(
      state.lines.where((e) => e.kind == TapeLineKind.normal).toList(),
    );

    if (state.equalsCount == 0) {
      final line = TapeLine(
        index: state.lines.length + 1,
        sign: TapeLineSign.plus,
        amount: subtotal,
        kind: TapeLineKind.subtotal,
        createdAt: DateTime.now(),
      );
      return state.copyWith(lines: [...state.lines, line], equalsCount: 1);
    }

    final line = TapeLine(
      index: state.lines.length + 1,
      sign: TapeLineSign.plus,
      amount: subtotal,
      kind: TapeLineKind.grandTotal,
      createdAt: DateTime.now(),
    );

    return state.copyWith(
      lines: [...state.lines, line],
      equalsCount: 0,
      cycle: state.cycle + 1,
      inputBuffer: '0',
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
      clearPendingExpression: true,
    );
  }

  DecimalValue multiply(DecimalValue a, DecimalValue b) => a.times(b);
  DecimalValue divide(DecimalValue a, DecimalValue b) => a.dividedBy(b);

  TapeSessionState setInterimResult(
    TapeSessionState state,
    DecimalValue value,
  ) {
    return state.copyWith(lastInterimResult: value);
  }

  TapeSessionState addInterimResultToTape(
    TapeSessionState state,
    TapeLineSign sign,
  ) {
    final interim = state.lastInterimResult;
    if (interim == null) return state;
    final line = TapeLine(
      index: state.lines.length + 1,
      sign: sign,
      amount: interim,
      kind: TapeLineKind.normal,
      createdAt: DateTime.now(),
    );
    return state.copyWith(
      lines: [...state.lines, line],
      clearInterimResult: true,
      equalsCount: 0,
      clearPendingLeftOperand: true,
      clearPendingOperation: true,
      clearPendingExpression: true,
    );
  }

  TapeSessionState memoryStore(TapeSessionState state, TapeMemorySlot slot) {
    final next = Map<TapeMemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = DecimalValue.parse(state.inputBuffer);
    return state.copyWith(memories: next);
  }

  TapeSessionState memoryRecall(TapeSessionState state, TapeMemorySlot slot) {
    final memory = state.memories[slot];
    if (memory == null) return state;
    return state.copyWith(inputBuffer: memory.toString());
  }

  TapeSessionState memoryAdd(TapeSessionState state, TapeMemorySlot slot) {
    final memory = state.memories[slot] ?? DecimalValue.zero();
    final value = DecimalValue.parse(state.inputBuffer);
    final next = Map<TapeMemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = memory.plus(value);
    return state.copyWith(memories: next);
  }

  TapeSessionState memorySubtract(TapeSessionState state, TapeMemorySlot slot) {
    final memory = state.memories[slot] ?? DecimalValue.zero();
    final value = DecimalValue.parse(state.inputBuffer);
    final next = Map<TapeMemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = memory.minus(value);
    return state.copyWith(memories: next);
  }

  TapeSessionState memoryClear(TapeSessionState state, TapeMemorySlot slot) {
    final next = Map<TapeMemorySlot, DecimalValue?>.from(state.memories)
      ..[slot] = null;
    return state.copyWith(memories: next);
  }

  DecimalValue _computeTotal(List<TapeLine> lines) {
    var total = DecimalValue.zero();
    for (final line in lines) {
      total = line.sign == TapeLineSign.plus
          ? total.plus(line.amount)
          : total.minus(line.amount);
    }
    return total;
  }
}
