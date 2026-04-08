import 'dart:math' as math;

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
    if (base.contains('.')) return state;
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
    return state.copyWith(
      currentInput: next,
      display: next,
      shouldResetInput: false,
    );
  }

  StandardCalculatorState clear(StandardCalculatorState state) {
    return state.copyWith(
      display: '0',
      expressionBuffer: '',
      clearRecentOperations: true,
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

  StandardCalculatorState backspace(StandardCalculatorState state) {
    if (state.shouldResetInput || state.currentInput == '0') return state;
    final next = state.currentInput.length == 1
        ? '0'
        : state.currentInput.substring(0, state.currentInput.length - 1);
    return state.copyWith(currentInput: next, display: next);
  }

  StandardCalculatorState setOperation(
    StandardCalculatorState state,
    CalcOperator op,
  ) {
    final symbol = switch (op) {
      CalcOperator.add => '+',
      CalcOperator.subtract => '-',
      CalcOperator.multiply => '*',
      CalcOperator.divide => '/',
    };
    final expr = state.shouldResetInput
        ? '${state.expressionBuffer}$symbol'
        : '${state.expressionBuffer}${state.currentInput}$symbol';
    return state.copyWith(
      expressionBuffer: expr,
      shouldResetInput: true,
      pendingOperator: op,
    );
  }

  StandardCalculatorState power(StandardCalculatorState state) {
    final expr = state.shouldResetInput
        ? '${state.expressionBuffer}^'
        : '${state.expressionBuffer}${state.currentInput}^';
    return state.copyWith(
      expressionBuffer: expr,
      shouldResetInput: true,
      pendingOperator: CalcOperator.multiply,
    );
  }

  StandardCalculatorState leftParen(StandardCalculatorState state) {
    final hasValue = !state.shouldResetInput && state.currentInput != '0';
    final shouldImplicitMultiply = hasValue || _endsWithValueExpression(state);
    final prefix = hasValue
        ? '${state.expressionBuffer}${state.currentInput}${shouldImplicitMultiply ? '*' : ''}('
        : '${state.expressionBuffer}${shouldImplicitMultiply ? '*' : ''}(';
    return state.copyWith(
      expressionBuffer: prefix,
      currentInput: '0',
      display: '0',
      shouldResetInput: false,
    );
  }

  StandardCalculatorState rightParen(StandardCalculatorState state) {
    final hasValue = !state.shouldResetInput;
    final expr = hasValue
        ? '${state.expressionBuffer}${state.currentInput})'
        : '${state.expressionBuffer})';
    return state.copyWith(
      expressionBuffer: expr,
      currentInput: '0',
      display: '0',
      shouldResetInput: true,
    );
  }

  StandardCalculatorState sqrt(StandardCalculatorState state) {
    final hasValue = !state.shouldResetInput && state.currentInput != '0';
    final needsMul = hasValue || _endsWithValueExpression(state);
    final expr = hasValue
        ? '${state.expressionBuffer}${needsMul ? '*' : ''}sqrt(${state.currentInput})'
        : '${state.expressionBuffer}${needsMul ? '*' : ''}sqrt(';
    return state.copyWith(
      expressionBuffer: expr,
      currentInput: '0',
      display: '0',
      shouldResetInput: !hasValue,
    );
  }

  StandardCalculatorState equals(StandardCalculatorState state) {
    final expression = _composeExpression(state);
    if (expression.trim().isEmpty) return state;
    try {
      final result = _evaluateExpression(expression);
      final nextHistory = List<String>.from(state.recentOperations)
        ..add('$expression = ${result.toString()}');
      while (nextHistory.length > 20) {
        nextHistory.removeAt(0);
      }
      return state.copyWith(
        accumulator: result,
        currentInput: result.toString(),
        display: result.toString(),
        expressionBuffer: '',
        recentOperations: nextHistory,
        clearPendingOperator: true,
        shouldResetInput: true,
      );
    } catch (_) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }
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

  DecimalValue _evaluateExpression(String expression) {
    final tokens = _tokenize(expression);
    final postfix = _toPostfix(tokens);
    final value = _evalPostfix(postfix);
    return DecimalValue.parse(value.toStringAsFixed(8));
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
      if (_isDigit(ch) || ch == '.') {
        final b = StringBuffer();
        while (i < input.length && (_isDigit(input[i]) || input[i] == '.')) {
          b.write(input[i]);
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
      throw ArgumentError('Geçersiz karakter: $ch');
    }
    return out;
  }

  List<String> _toPostfix(List<String> tokens) {
    final output = <String>[];
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
      final isNumber = double.tryParse(tok) != null;
      if (isNumber) {
        output.add(tok);
        prev = tok;
        continue;
      }

      if (tok == 'sqrt') {
        stack.add(tok);
        prev = tok;
        continue;
      }

      if (tok == '(') {
        stack.add(tok);
        prev = tok;
        continue;
      }

      if (tok == ')') {
        while (stack.isNotEmpty && stack.last != '(') {
          output.add(stack.removeLast());
        }
        if (stack.isEmpty) throw ArgumentError('Parantez hatası');
        stack.removeLast();
        if (stack.isNotEmpty && stack.last == 'sqrt') {
          output.add(stack.removeLast());
        }
        prev = tok;
        continue;
      }

      var op = tok;
      if (op == '-' && (prev == null || '()+-*/^'.contains(prev))) {
        output.add('0');
      }

      while (stack.isNotEmpty &&
          stack.last != '(' &&
          ((rightAssoc(op) && prec(op) < prec(stack.last)) ||
              (!rightAssoc(op) && prec(op) <= prec(stack.last)))) {
        output.add(stack.removeLast());
      }
      stack.add(op);
      prev = op;
    }

    while (stack.isNotEmpty) {
      final t = stack.removeLast();
      if (t == '(') throw ArgumentError('Parantez hatası');
      output.add(t);
    }
    return output;
  }

  double _evalPostfix(List<String> postfix) {
    final stack = <double>[];
    for (final tok in postfix) {
      final num = double.tryParse(tok);
      if (num != null) {
        stack.add(num);
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

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  String _composeExpression(StandardCalculatorState state) {
    if (state.shouldResetInput) return state.expressionBuffer;
    return '${state.expressionBuffer}${state.currentInput}';
  }

  bool _endsWithValueExpression(StandardCalculatorState state) {
    final exp = state.expressionBuffer.trimRight();
    if (exp.isEmpty) return false;
    final last = exp[exp.length - 1];
    return _isDigit(last) || last == ')';
  }
}
