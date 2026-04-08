import '../../../core/types/decimal_value.dart';

enum CalcOperator { add, subtract, multiply, divide }

enum MemorySlot { m1, m2, m3 }

class StandardCalculatorState {
  const StandardCalculatorState({
    required this.display,
    required this.currentInput,
    required this.accumulator,
    required this.pendingOperator,
    required this.shouldResetInput,
    required this.memories,
  });

  factory StandardCalculatorState.initial() => StandardCalculatorState(
    display: '0',
    currentInput: '0',
    accumulator: DecimalValue.zero(),
    pendingOperator: null,
    shouldResetInput: false,
    memories: const {
      MemorySlot.m1: null,
      MemorySlot.m2: null,
      MemorySlot.m3: null,
    },
  );

  final String display;
  final String currentInput;
  final DecimalValue accumulator;
  final CalcOperator? pendingOperator;
  final bool shouldResetInput;
  final Map<MemorySlot, DecimalValue?> memories;

  StandardCalculatorState copyWith({
    String? display,
    String? currentInput,
    DecimalValue? accumulator,
    CalcOperator? pendingOperator,
    bool clearPendingOperator = false,
    bool? shouldResetInput,
    Map<MemorySlot, DecimalValue?>? memories,
  }) {
    return StandardCalculatorState(
      display: display ?? this.display,
      currentInput: currentInput ?? this.currentInput,
      accumulator: accumulator ?? this.accumulator,
      pendingOperator: clearPendingOperator
          ? null
          : (pendingOperator ?? this.pendingOperator),
      shouldResetInput: shouldResetInput ?? this.shouldResetInput,
      memories: memories ?? this.memories,
    );
  }
}
