import '../../../core/types/decimal_value.dart';

enum TapeLineSign { plus, minus }

enum TapeLineKind { normal, subtotal, grandTotal, reference }

enum TapePendingOperation { multiply, divide }

enum TapeMemorySlot { m1, m2, m3 }

class TapeLine {
  const TapeLine({
    required this.index,
    required this.sign,
    required this.amount,
    required this.kind,
    required this.createdAt,
  });

  final int index;
  final TapeLineSign sign;
  final DecimalValue amount;
  final TapeLineKind kind;
  final DateTime createdAt;
}

class TapeSessionState {
  const TapeSessionState({
    required this.lines,
    required this.inputBuffer,
    required this.equalsCount,
    required this.cycle,
    required this.lastInterimResult,
    required this.pendingOperation,
    required this.pendingLeftOperand,
    required this.pendingExpression,
    required this.memories,
  });

  factory TapeSessionState.initial() => const TapeSessionState(
    lines: [],
    inputBuffer: '0',
    equalsCount: 0,
    cycle: 1,
    lastInterimResult: null,
    pendingOperation: null,
    pendingLeftOperand: null,
    pendingExpression: null,
    memories: {
      TapeMemorySlot.m1: null,
      TapeMemorySlot.m2: null,
      TapeMemorySlot.m3: null,
    },
  );

  final List<TapeLine> lines;
  final String inputBuffer;
  final int equalsCount;
  final int cycle;
  final DecimalValue? lastInterimResult;
  final TapePendingOperation? pendingOperation;
  final DecimalValue? pendingLeftOperand;
  final String? pendingExpression;
  final Map<TapeMemorySlot, DecimalValue?> memories;

  TapeSessionState copyWith({
    List<TapeLine>? lines,
    String? inputBuffer,
    int? equalsCount,
    int? cycle,
    DecimalValue? lastInterimResult,
    TapePendingOperation? pendingOperation,
    DecimalValue? pendingLeftOperand,
    String? pendingExpression,
    Map<TapeMemorySlot, DecimalValue?>? memories,
    bool clearInterimResult = false,
    bool clearPendingOperation = false,
    bool clearPendingLeftOperand = false,
    bool clearPendingExpression = false,
  }) {
    return TapeSessionState(
      lines: lines ?? this.lines,
      inputBuffer: inputBuffer ?? this.inputBuffer,
      equalsCount: equalsCount ?? this.equalsCount,
      cycle: cycle ?? this.cycle,
      lastInterimResult: clearInterimResult
          ? null
          : (lastInterimResult ?? this.lastInterimResult),
      pendingOperation: clearPendingOperation
          ? null
          : (pendingOperation ?? this.pendingOperation),
      pendingLeftOperand: clearPendingLeftOperand
          ? null
          : (pendingLeftOperand ?? this.pendingLeftOperand),
      pendingExpression: clearPendingExpression
          ? null
          : (pendingExpression ?? this.pendingExpression),
      memories: memories ?? this.memories,
    );
  }
}
