import 'dart:math' as math;

import '../../../core/types/decimal_value.dart';
import 'tape_models.dart';

class TapeEngine {
  TapeSessionState inputDigit(TapeSessionState state, String digit) {
    final next = state.inputBuffer == '0'
        ? digit
        : '${state.inputBuffer}$digit';
    return state.copyWith(
      inputBuffer: next,
      clearInterimResult: true,
      clearPendingExpression: true,
    );
  }

  TapeSessionState toggleSign(TapeSessionState state) {
    final current = DecimalValue.parse(state.inputBuffer);
    return state.copyWith(
      inputBuffer: current.negated().toString(),
      clearInterimResult: true,
      clearPendingExpression: true,
    );
  }

  TapeSessionState inputDecimal(TapeSessionState state) {
    if (state.inputBuffer.contains('.')) return state;
    return state.copyWith(
      inputBuffer: '${state.inputBuffer}.',
      clearInterimResult: true,
      clearPendingExpression: true,
    );
  }

  TapeSessionState clearEntry(TapeSessionState state) =>
      state.copyWith(inputBuffer: '0', clearExpressionBuffer: true);

  TapeSessionState backspace(TapeSessionState state) {
    final raw = state.inputBuffer;
    if (raw == '0') return state;
    final next = raw.length <= 1 ? '0' : raw.substring(0, raw.length - 1);
    if (next == '-' || next.isEmpty) {
      return state.copyWith(
        inputBuffer: '0',
        clearInterimResult: true,
        clearPendingExpression: true,
      );
    }
    return state.copyWith(
      inputBuffer: next,
      clearInterimResult: true,
      clearPendingExpression: true,
    );
  }

  TapeSessionState clearAll(TapeSessionState state) =>
      TapeSessionState.initial().copyWith(
        memories: state.memories,
        clearExpressionBuffer: true,
      );

  TapeSessionState clearAllMemories(TapeSessionState state) {
    return state.copyWith(
      memories: {
        TapeMemorySlot.m1: null,
        TapeMemorySlot.m2: null,
        TapeMemorySlot.m3: null,
      },
    );
  }

  TapeSessionState addSignedLine(TapeSessionState state, TapeLineSign sign) {
    final amount = DecimalValue.parse(state.inputBuffer);
    final expression = state.lastInterimResult == null
        ? null
        : state.pendingExpression;
    final line = TapeLine(
      index: state.lines.length + 1,
      sign: sign,
      amount: amount,
      kind: TapeLineKind.normal,
      expression: expression,
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
      clearExpressionBuffer: true,
    );
  }

  TapeSessionState leftParen(TapeSessionState state) {
    final hasValue = state.inputBuffer != '0';
    final endsWithValue = _endsWithValue(state.expressionBuffer);
    final mul = (hasValue || endsWithValue) ? '*' : '';
    final next = hasValue
        ? '${state.expressionBuffer}${state.inputBuffer}$mul('
        : '${state.expressionBuffer}$mul(';
    return state.copyWith(
      expressionBuffer: next,
      inputBuffer: '0',
      clearPendingExpression: true,
      clearInterimResult: true,
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
    );
  }

  TapeSessionState rightParen(TapeSessionState state) {
    final next = state.inputBuffer != '0'
        ? '${state.expressionBuffer}${state.inputBuffer})'
        : '${state.expressionBuffer})';
    return state.copyWith(
      expressionBuffer: next,
      inputBuffer: '0',
      clearPendingExpression: true,
      clearInterimResult: true,
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
    );
  }

  TapeSessionState sqrt(TapeSessionState state) {
    final hasValue = state.inputBuffer != '0';
    final endsWithValue = _endsWithValue(state.expressionBuffer);
    final mul = (hasValue || endsWithValue) ? '*' : '';
    final next = hasValue
        ? '${state.expressionBuffer}$mul'
              'sqrt(${state.inputBuffer})'
        : '${state.expressionBuffer}$mul'
              'sqrt(';
    return state.copyWith(
      expressionBuffer: next,
      inputBuffer: '0',
      clearPendingExpression: true,
      clearInterimResult: true,
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
    );
  }

  TapeSessionState power(TapeSessionState state) {
    var base = state.expressionBuffer;
    if (state.inputBuffer != '0') {
      base = '$base${state.inputBuffer}';
    }
    if (!_endsWithValue(base)) {
      return state;
    }
    final next = '$base^';
    return state.copyWith(
      expressionBuffer: next,
      inputBuffer: '0',
      clearPendingExpression: true,
      clearInterimResult: true,
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
    );
  }

  TapeSessionState expressionOperator(TapeSessionState state, String op) {
    var base = state.expressionBuffer;
    if (state.inputBuffer != '0') {
      base = '$base${state.inputBuffer}';
    }
    if (base.isEmpty) return state;
    if (_endsWithOperator(base)) {
      base = base.substring(0, base.length - 1);
    }
    if (!_endsWithValue(base)) return state;
    final next = '$base$op';
    return state.copyWith(
      expressionBuffer: next,
      inputBuffer: '0',
      clearPendingExpression: true,
      clearInterimResult: true,
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
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
    final expression = '${value.toString()} % = ${result.toString()}';
    return state.copyWith(
      inputBuffer: result.toString(),
      lastInterimResult: result,
      pendingExpression: expression,
      clearPendingLeftOperand: true,
      clearPendingOperation: true,
    );
  }

  TapeSessionState applyVat(
    TapeSessionState state, {
    required DecimalValue rate,
    required TapeVatMode mode,
  }) {
    final value = DecimalValue.parse(state.inputBuffer);
    final rateTag = '%${rate.toString()}';

    if (mode == TapeVatMode.excluded) {
      final gross = value.plus(rate.percentOf(value));
      return state.copyWith(
        inputBuffer: gross.toString(),
        lastInterimResult: gross,
        pendingExpression:
            '${value.toString()} + VAT($rateTag) = ${gross.toString()}',
        clearPendingLeftOperand: true,
        clearPendingOperation: true,
      );
    }

    final divisor = DecimalValue.parse(
      '1',
    ).plus(rate.dividedBy(DecimalValue.parse('100')));
    final net = value.dividedBy(divisor);
    return state.copyWith(
      inputBuffer: net.toString(),
      lastInterimResult: net,
      pendingExpression:
          '${value.toString()} VAT dahil ($rateTag) -> ${net.toString()}',
      clearPendingLeftOperand: true,
      clearPendingOperation: true,
    );
  }

  TapeSessionState applyEffectiveFxRate(
    TapeSessionState state, {
    required String currencyLabel,
    required DecimalValue rate,
  }) {
    if (state.pendingOperation == TapePendingOperation.multiply &&
        state.pendingLeftOperand != null) {
      final left = state.pendingLeftOperand!;
      final result = left.times(rate);
      return state.copyWith(
        inputBuffer: result.toString(),
        lastInterimResult: result,
        pendingExpression:
            '${left.toString()} $currencyLabel × ${rate.toString()} = ${result.toString()}',
        clearPendingOperation: true,
        clearPendingLeftOperand: true,
      );
    }

    return state.copyWith(
      inputBuffer: rate.toString(),
      lastInterimResult: rate,
      pendingExpression: '$currencyLabel efektif satış = ${rate.toString()}',
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
    );
  }

  TapeSessionState applyFormulaResult(
    TapeSessionState state, {
    required String expression,
    required DecimalValue result,
  }) {
    return state.copyWith(
      inputBuffer: result.toString(),
      lastInterimResult: result,
      pendingExpression: '$expression = ${result.toString()}',
      clearPendingOperation: true,
      clearPendingLeftOperand: true,
    );
  }

  TapeSessionState equals(TapeSessionState state) {
    if (state.expressionBuffer.isNotEmpty) {
      final expression = '${state.expressionBuffer}${state.inputBuffer}';
      try {
        final raw = _evaluateExpression(expression);
        final result = DecimalValue.parse(raw.toStringAsFixed(8));
        return state.copyWith(
          inputBuffer: result.toString(),
          lastInterimResult: result,
          pendingExpression: '$expression = ${result.toString()}',
          clearExpressionBuffer: true,
          clearPendingOperation: true,
          clearPendingLeftOperand: true,
        );
      } catch (_) {
        return state.copyWith(
          pendingExpression: '$expression = Hata',
          clearExpressionBuffer: true,
          clearPendingOperation: true,
          clearPendingLeftOperand: true,
        );
      }
    }

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
      final expression =
          '${state.pendingLeftOperand} $op ${right.toString()} = ${result.toString()}';
      return state.copyWith(
        inputBuffer: result.toString(),
        lastInterimResult: result,
        pendingExpression: expression,
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
      expression: state.pendingExpression,
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

  bool _endsWithValue(String expression) {
    final exp = expression.trimRight();
    if (exp.isEmpty) return false;
    final c = exp[exp.length - 1];
    return (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) || c == ')';
  }

  bool _endsWithOperator(String expression) {
    final exp = expression.trimRight();
    if (exp.isEmpty) return false;
    return '+-*/^'.contains(exp[exp.length - 1]);
  }

  double _evaluateExpression(String expression) {
    final tokens = _tokenize(expression);
    final postfix = _toPostfix(tokens);
    return _evalPostfix(postfix);
  }

  List<String> _tokenize(String input) {
    final out = <String>[];
    var i = 0;
    while (i < input.length) {
      final ch = input[i];
      if (ch.trim().isEmpty) {
        i++;
        continue;
      }
      if ((ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || ch == '.') {
        final b = StringBuffer();
        while (i < input.length) {
          final c = input[i];
          final isDigit = c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
          if (!isDigit && c != '.') break;
          b.write(c);
          i++;
        }
        out.add(b.toString());
        continue;
      }
      if (i + 3 < input.length && input.substring(i, i + 4) == 'sqrt') {
        out.add('sqrt');
        i += 4;
        continue;
      }
      if ('+-*/^()'.contains(ch)) {
        out.add(ch);
        i++;
        continue;
      }
      throw ArgumentError('Geçersiz karakter');
    }
    return out;
  }

  List<String> _toPostfix(List<String> tokens) {
    final out = <String>[];
    final stack = <String>[];
    String? prev;

    int prec(String op) => switch (op) {
      '+' || '-' => 1,
      '*' || '/' => 2,
      '^' => 3,
      'sqrt' => 4,
      _ => 0,
    };
    bool rightAssoc(String op) => op == '^';

    for (final tok in tokens) {
      if (double.tryParse(tok) != null) {
        out.add(tok);
        prev = tok;
        continue;
      }
      if (tok == 'sqrt' || tok == '(') {
        stack.add(tok);
        prev = tok;
        continue;
      }
      if (tok == ')') {
        while (stack.isNotEmpty && stack.last != '(') {
          out.add(stack.removeLast());
        }
        if (stack.isEmpty) throw ArgumentError('Parantez hatası');
        stack.removeLast();
        if (stack.isNotEmpty && stack.last == 'sqrt') {
          out.add(stack.removeLast());
        }
        prev = tok;
        continue;
      }

      var op = tok;
      if (op == '-' && (prev == null || '()+-*/^'.contains(prev))) {
        out.add('0');
      }
      while (stack.isNotEmpty &&
          stack.last != '(' &&
          ((rightAssoc(op) && prec(op) < prec(stack.last)) ||
              (!rightAssoc(op) && prec(op) <= prec(stack.last)))) {
        out.add(stack.removeLast());
      }
      stack.add(op);
      prev = op;
    }
    while (stack.isNotEmpty) {
      final t = stack.removeLast();
      if (t == '(') throw ArgumentError('Parantez hatası');
      out.add(t);
    }
    return out;
  }

  double _evalPostfix(List<String> postfix) {
    final stack = <double>[];
    for (final tok in postfix) {
      final n = double.tryParse(tok);
      if (n != null) {
        stack.add(n);
        continue;
      }
      if (tok == 'sqrt') {
        if (stack.isEmpty) throw ArgumentError('Eksik operand');
        final v = stack.removeLast();
        if (v < 0) throw ArgumentError('Negatif karekök');
        stack.add(math.sqrt(v));
        continue;
      }
      if (stack.length < 2) throw ArgumentError('Eksik operand');
      final b = stack.removeLast();
      final a = stack.removeLast();
      final r = switch (tok) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        '/' => b == 0 ? (throw ArgumentError('Sıfıra bölme')) : a / b,
        '^' => math.pow(a, b).toDouble(),
        _ => throw ArgumentError('Bilinmeyen op'),
      };
      stack.add(r);
    }
    if (stack.length != 1) throw ArgumentError('İfade hatası');
    return stack.single;
  }
}
