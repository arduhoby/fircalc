import 'dart:math' as math;

import '../../../core/types/decimal_value.dart';
import 'standard_calculator_state.dart';

class QuadrilateralPoint {
  const QuadrilateralPoint({required this.x, required this.y});

  final double x;
  final double y;
}

class LatLonPoint {
  const LatLonPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class RandomGenerationRequest {
  const RandomGenerationRequest({
    required this.min,
    required this.max,
    required this.count,
    required this.step,
    required this.allowFloat,
    required this.decimalDigits,
  });

  final double min;
  final double max;
  final int count;
  final double step;
  final bool allowFloat;
  final int decimalDigits;
}

enum ConvertCategory {
  length,
  area,
  volume,
  weight,
  time,
  temperature,
  speed,
  pressure,
  energy,
  power,
  angle,
  data,
  electricUnit,
}

class ConvertUnit {
  const ConvertUnit({
    required this.id,
    required this.label,
    required this.category,
    required this.toBase,
    required this.fromBase,
  });

  final String id;
  final String label;
  final ConvertCategory category;
  final double Function(double value) toBase;
  final double Function(double value) fromBase;
}

enum ElectricOhmTarget { voltage, current, resistance }

enum ElectricPowerTarget { power, voltage, current }

class DateDifferenceResult {
  const DateDifferenceResult({
    required this.totalDays,
    required this.totalWeeks,
    required this.totalHours,
    required this.totalMinutes,
    required this.wholeMonths,
    required this.wholeYears,
  });

  final int totalDays;
  final double totalWeeks;
  final int totalHours;
  final int totalMinutes;
  final int wholeMonths;
  final int wholeYears;
}

const convertUnits = <ConvertUnit>[
  ConvertUnit(
    id: 'mm',
    label: 'mm',
    category: ConvertCategory.length,
    toBase: _identityMilli,
    fromBase: _identityMilli,
  ),
  ConvertUnit(
    id: 'cm',
    label: 'cm',
    category: ConvertCategory.length,
    toBase: _centiToMilli,
    fromBase: _milliToCenti,
  ),
  ConvertUnit(
    id: 'm',
    label: 'm',
    category: ConvertCategory.length,
    toBase: _meterToMilli,
    fromBase: _milliToMeter,
  ),
  ConvertUnit(
    id: 'km',
    label: 'km',
    category: ConvertCategory.length,
    toBase: _kmToMilli,
    fromBase: _milliToKm,
  ),
  ConvertUnit(
    id: 'inch',
    label: 'inch',
    category: ConvertCategory.length,
    toBase: _inchToMilli,
    fromBase: _milliToInch,
  ),
  ConvertUnit(
    id: 'm2',
    label: 'm²',
    category: ConvertCategory.area,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'km2',
    label: 'km²',
    category: ConvertCategory.area,
    toBase: _km2ToM2,
    fromBase: _m2ToKm2,
  ),
  ConvertUnit(
    id: 'hectare',
    label: 'hektar',
    category: ConvertCategory.area,
    toBase: _hectareToM2,
    fromBase: _m2ToHectare,
  ),
  ConvertUnit(
    id: 'decare',
    label: 'donum',
    category: ConvertCategory.area,
    toBase: _decareToM2,
    fromBase: _m2ToDecare,
  ),
  ConvertUnit(
    id: 'ft2',
    label: 'ft²',
    category: ConvertCategory.area,
    toBase: _ft2ToM2,
    fromBase: _m2ToFt2,
  ),
  ConvertUnit(
    id: 'ml',
    label: 'mL',
    category: ConvertCategory.volume,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'l',
    label: 'L',
    category: ConvertCategory.volume,
    toBase: _literToMilliLiter,
    fromBase: _milliLiterToLiter,
  ),
  ConvertUnit(
    id: 'm3',
    label: 'm³',
    category: ConvertCategory.volume,
    toBase: _m3ToMilliLiter,
    fromBase: _milliLiterToM3,
  ),
  ConvertUnit(
    id: 'g',
    label: 'g',
    category: ConvertCategory.weight,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'kg',
    label: 'kg',
    category: ConvertCategory.weight,
    toBase: _kgToGram,
    fromBase: _gramToKg,
  ),
  ConvertUnit(
    id: 'lb',
    label: 'lb',
    category: ConvertCategory.weight,
    toBase: _lbToGram,
    fromBase: _gramToLb,
  ),
  ConvertUnit(
    id: 'sec',
    label: 'sn',
    category: ConvertCategory.time,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'min',
    label: 'dk',
    category: ConvertCategory.time,
    toBase: _minuteToSecond,
    fromBase: _secondToMinute,
  ),
  ConvertUnit(
    id: 'hour',
    label: 'saat',
    category: ConvertCategory.time,
    toBase: _hourToSecond,
    fromBase: _secondToHour,
  ),
  ConvertUnit(
    id: 'day',
    label: 'gun',
    category: ConvertCategory.time,
    toBase: _dayToSecond,
    fromBase: _secondToDay,
  ),
  ConvertUnit(
    id: 'c',
    label: '°C',
    category: ConvertCategory.temperature,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'f',
    label: '°F',
    category: ConvertCategory.temperature,
    toBase: _fToC,
    fromBase: _cToF,
  ),
  ConvertUnit(
    id: 'k',
    label: 'K',
    category: ConvertCategory.temperature,
    toBase: _kToC,
    fromBase: _cToK,
  ),
  ConvertUnit(
    id: 'mps',
    label: 'm/s',
    category: ConvertCategory.speed,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'kmh',
    label: 'km/h',
    category: ConvertCategory.speed,
    toBase: _kmhToMps,
    fromBase: _mpsToKmh,
  ),
  ConvertUnit(
    id: 'mph',
    label: 'mph',
    category: ConvertCategory.speed,
    toBase: _mphToMps,
    fromBase: _mpsToMph,
  ),
  ConvertUnit(
    id: 'pa',
    label: 'Pa',
    category: ConvertCategory.pressure,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'bar',
    label: 'bar',
    category: ConvertCategory.pressure,
    toBase: _barToPa,
    fromBase: _paToBar,
  ),
  ConvertUnit(
    id: 'psi',
    label: 'psi',
    category: ConvertCategory.pressure,
    toBase: _psiToPa,
    fromBase: _paToPsi,
  ),
  ConvertUnit(
    id: 'j',
    label: 'J',
    category: ConvertCategory.energy,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'kj',
    label: 'kJ',
    category: ConvertCategory.energy,
    toBase: _kiloToBase,
    fromBase: _baseToKilo,
  ),
  ConvertUnit(
    id: 'wh',
    label: 'Wh',
    category: ConvertCategory.energy,
    toBase: _whToJoule,
    fromBase: _jouleToWh,
  ),
  ConvertUnit(
    id: 'kwh',
    label: 'kWh',
    category: ConvertCategory.energy,
    toBase: _kwhToJoule,
    fromBase: _jouleToKwh,
  ),
  ConvertUnit(
    id: 'w',
    label: 'W',
    category: ConvertCategory.power,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'kw',
    label: 'kW',
    category: ConvertCategory.power,
    toBase: _kiloToBase,
    fromBase: _baseToKilo,
  ),
  ConvertUnit(
    id: 'hp',
    label: 'hp',
    category: ConvertCategory.power,
    toBase: _hpToW,
    fromBase: _wToHp,
  ),
  ConvertUnit(
    id: 'deg',
    label: '°',
    category: ConvertCategory.angle,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'rad',
    label: 'rad',
    category: ConvertCategory.angle,
    toBase: _radToDeg,
    fromBase: _degToRad,
  ),
  ConvertUnit(
    id: 'mb',
    label: 'MB',
    category: ConvertCategory.data,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'gb',
    label: 'GB',
    category: ConvertCategory.data,
    toBase: _gbToMb,
    fromBase: _mbToGb,
  ),
  ConvertUnit(
    id: 'tb',
    label: 'TB',
    category: ConvertCategory.data,
    toBase: _tbToMb,
    fromBase: _mbToTb,
  ),
  ConvertUnit(
    id: 'ma',
    label: 'mA',
    category: ConvertCategory.electricUnit,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'a',
    label: 'A',
    category: ConvertCategory.electricUnit,
    toBase: _ampToMilliAmp,
    fromBase: _milliAmpToAmp,
  ),
  ConvertUnit(
    id: 'mv',
    label: 'mV',
    category: ConvertCategory.electricUnit,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'v',
    label: 'V',
    category: ConvertCategory.electricUnit,
    toBase: _voltToMilliVolt,
    fromBase: _milliVoltToVolt,
  ),
  ConvertUnit(
    id: 'ohm',
    label: 'Ohm',
    category: ConvertCategory.electricUnit,
    toBase: _identity,
    fromBase: _identity,
  ),
  ConvertUnit(
    id: 'kohm',
    label: 'kOhm',
    category: ConvertCategory.electricUnit,
    toBase: _kiloToBase,
    fromBase: _baseToKilo,
  ),
];

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

  StandardCalculatorState circleArea(
    StandardCalculatorState state, {
    required double radius,
  }) {
    if (!radius.isFinite || radius < 0) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }

    final area = math.pi * radius * radius;
    return _applyNumericResult(
      state,
      result: area,
      historyLabel: 'SQR(circle r=$radius)',
    );
  }

  StandardCalculatorState quadrilateralArea(
    StandardCalculatorState state, {
    required List<QuadrilateralPoint> points,
  }) {
    if (points.length != 4 ||
        points.any((point) => !point.x.isFinite || !point.y.isFinite)) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }

    var area = 0.0;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      area += (current.x * next.y) - (current.y * next.x);
    }

    return _applyNumericResult(
      state,
      result: area.abs() / 2,
      historyLabel:
          'SQR(quad ${points.map((point) => '(${point.x},${point.y})').join(', ')})',
    );
  }

  StandardCalculatorState rectangleArea(
    StandardCalculatorState state, {
    required double shortSide,
    required double longSide,
  }) {
    if (!shortSide.isFinite ||
        !longSide.isFinite ||
        shortSide <= 0 ||
        longSide <= 0) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }

    return _applyNumericResult(
      state,
      result: shortSide * longSide,
      historyLabel: 'SQR(rect $shortSide x $longSide)',
    );
  }

  StandardCalculatorState latLonArea(
    StandardCalculatorState state, {
    required List<LatLonPoint> points,
  }) {
    if (points.length < 3 ||
        points.any(
          (point) =>
              !point.latitude.isFinite ||
              !point.longitude.isFinite ||
              point.latitude < -90 ||
              point.latitude > 90 ||
              point.longitude < -180 ||
              point.longitude > 180,
        )) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }

    const earthRadiusMeters = 6378137.0;
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final lat1 = current.latitude * math.pi / 180;
      final lat2 = next.latitude * math.pi / 180;
      final lon1 = current.longitude * math.pi / 180;
      final lon2 = next.longitude * math.pi / 180;
      sum += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
    }

    final area = (sum * earthRadiusMeters * earthRadiusMeters / 2).abs();
    return _applyNumericResult(
      state,
      result: area,
      historyLabel: 'SQR(latlon ${points.length} nokta)',
    );
  }

  StandardCalculatorState generateRandom(
    StandardCalculatorState state, {
    required RandomGenerationRequest request,
  }) {
    if (!request.min.isFinite ||
        !request.max.isFinite ||
        request.max < request.min ||
        request.count <= 0 ||
        !request.step.isFinite ||
        request.step <= 0 ||
        request.decimalDigits < 0) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }

    final values = request.allowFloat
        ? _generateUniqueFloats(request)
        : _generateUniqueIntegers(request);
    if (values == null) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }

    final resultText = values.join(', ');
    final nextHistory = List<String>.from(state.recentOperations)
      ..add(
        'RND(${request.min}-${request.max}, adet:${request.count}, adim:${request.step}, '
        '${request.allowFloat ? 'float/${request.decimalDigits}' : 'int'}) = $resultText',
      );
    while (nextHistory.length > 20) {
      nextHistory.removeAt(0);
    }

    final singleValue = values.length == 1 ? values.first : null;
    return state.copyWith(
      display: resultText,
      currentInput: singleValue ?? '0',
      expressionBuffer: '',
      recentOperations: nextHistory,
      clearPendingOperator: true,
      shouldResetInput: true,
    );
  }

  StandardCalculatorState convertUnit(
    StandardCalculatorState state, {
    required ConvertUnit from,
    required ConvertUnit to,
    required double value,
  }) {
    if (!value.isFinite || from.category != to.category) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }
    final base = from.toBase(value);
    final result = to.fromBase(base);
    return _applyNumericResult(
      state,
      result: result,
      historyLabel: 'CONVERT(${from.label}->${to.label} $value)',
    );
  }

  StandardCalculatorState electricOhmLaw(
    StandardCalculatorState state, {
    required ElectricOhmTarget target,
    double? voltage,
    double? current,
    double? resistance,
  }) {
    final result = switch (target) {
      ElectricOhmTarget.voltage when current != null && resistance != null =>
        current * resistance,
      ElectricOhmTarget.current
          when voltage != null && resistance != null && resistance != 0 =>
        voltage / resistance,
      ElectricOhmTarget.resistance
          when voltage != null && current != null && current != 0 =>
        voltage / current,
      _ => double.nan,
    };
    return _applyNumericResult(
      state,
      result: result,
      historyLabel: 'ELEC(ohm ${target.name})',
    );
  }

  StandardCalculatorState electricPower(
    StandardCalculatorState state, {
    required ElectricPowerTarget target,
    double? power,
    double? voltage,
    double? current,
  }) {
    final result = switch (target) {
      ElectricPowerTarget.power when voltage != null && current != null =>
        voltage * current,
      ElectricPowerTarget.voltage
          when power != null && current != null && current != 0 =>
        power / current,
      ElectricPowerTarget.current
          when power != null && voltage != null && voltage != 0 =>
        power / voltage,
      _ => double.nan,
    };
    return _applyNumericResult(
      state,
      result: result,
      historyLabel: 'ELEC(power ${target.name})',
    );
  }

  DateDifferenceResult calculateDateDifference(DateTime start, DateTime end) {
    final orderedStart = start.isBefore(end) ? start : end;
    final orderedEnd = start.isBefore(end) ? end : start;
    final duration = orderedEnd.difference(orderedStart);

    var months =
        ((orderedEnd.year - orderedStart.year) * 12) +
        (orderedEnd.month - orderedStart.month);
    if (orderedEnd.day < orderedStart.day) {
      months -= 1;
    }
    final years = months ~/ 12;

    return DateDifferenceResult(
      totalDays: duration.inDays,
      totalWeeks: duration.inHours / (24 * 7),
      totalHours: duration.inHours,
      totalMinutes: duration.inMinutes,
      wholeMonths: months,
      wholeYears: years,
    );
  }

  StandardCalculatorState applyTextResult(
    StandardCalculatorState state, {
    required String display,
    required String historyLabel,
    String? currentInput,
  }) {
    final nextHistory = List<String>.from(state.recentOperations)
      ..add('$historyLabel = $display');
    while (nextHistory.length > 20) {
      nextHistory.removeAt(0);
    }
    return state.copyWith(
      display: display,
      currentInput: currentInput ?? state.currentInput,
      expressionBuffer: '',
      recentOperations: nextHistory,
      clearPendingOperator: true,
      shouldResetInput: true,
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

  StandardCalculatorState _applyNumericResult(
    StandardCalculatorState state, {
    required double result,
    required String historyLabel,
  }) {
    if (!result.isFinite) {
      return state.copyWith(display: 'Hata', shouldResetInput: true);
    }

    final decimal = DecimalValue.parse(result.toStringAsFixed(8));
    final nextHistory = List<String>.from(state.recentOperations)
      ..add('$historyLabel = ${decimal.toString()}');
    while (nextHistory.length > 20) {
      nextHistory.removeAt(0);
    }

    return state.copyWith(
      accumulator: decimal,
      currentInput: decimal.toString(),
      display: decimal.toString(),
      expressionBuffer: '',
      recentOperations: nextHistory,
      clearPendingOperator: true,
      shouldResetInput: true,
    );
  }

  List<String>? _generateUniqueIntegers(RandomGenerationRequest request) {
    final step = request.step.round();
    if ((request.step - step).abs() > 1e-9) return null;
    final start = request.min.ceil();
    final end = request.max.floor();
    if (end < start) return null;

    final pool = <int>[];
    for (var value = start; value <= end; value += step) {
      pool.add(value);
    }
    if (request.count > pool.length) return null;

    pool.shuffle(math.Random());
    return pool.take(request.count).map((value) => value.toString()).toList();
  }

  List<String>? _generateUniqueFloats(RandomGenerationRequest request) {
    final scale = math.pow(10, request.decimalDigits).toInt();
    final scaledStep = request.step * scale;
    final step = scaledStep.round();
    if ((scaledStep - step).abs() > 1e-9 || step <= 0) return null;
    final start = (request.min * scale).ceil();
    final end = (request.max * scale).floor();
    if (end < start) return null;

    final pool = <int>[];
    for (var value = start; value <= end; value += step) {
      pool.add(value);
    }
    if (request.count > pool.length) return null;

    pool.shuffle(math.Random());
    return pool
        .take(request.count)
        .map((value) => (value / scale).toStringAsFixed(request.decimalDigits))
        .toList();
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

double _identity(double value) => value;
double _identityMilli(double value) => value;
double _centiToMilli(double value) => value * 10;
double _milliToCenti(double value) => value / 10;
double _meterToMilli(double value) => value * 1000;
double _milliToMeter(double value) => value / 1000;
double _kmToMilli(double value) => value * 1000000;
double _milliToKm(double value) => value / 1000000;
double _inchToMilli(double value) => value * 25.4;
double _milliToInch(double value) => value / 25.4;
double _km2ToM2(double value) => value * 1000000;
double _m2ToKm2(double value) => value / 1000000;
double _hectareToM2(double value) => value * 10000;
double _m2ToHectare(double value) => value / 10000;
double _decareToM2(double value) => value * 1000;
double _m2ToDecare(double value) => value / 1000;
double _ft2ToM2(double value) => value * 0.092903;
double _m2ToFt2(double value) => value / 0.092903;
double _literToMilliLiter(double value) => value * 1000;
double _milliLiterToLiter(double value) => value / 1000;
double _m3ToMilliLiter(double value) => value * 1000000;
double _milliLiterToM3(double value) => value / 1000000;
double _kgToGram(double value) => value * 1000;
double _gramToKg(double value) => value / 1000;
double _lbToGram(double value) => value * 453.59237;
double _gramToLb(double value) => value / 453.59237;
double _minuteToSecond(double value) => value * 60;
double _secondToMinute(double value) => value / 60;
double _hourToSecond(double value) => value * 3600;
double _secondToHour(double value) => value / 3600;
double _dayToSecond(double value) => value * 86400;
double _secondToDay(double value) => value / 86400;
double _fToC(double value) => (value - 32) * 5 / 9;
double _cToF(double value) => (value * 9 / 5) + 32;
double _kToC(double value) => value - 273.15;
double _cToK(double value) => value + 273.15;
double _kmhToMps(double value) => value / 3.6;
double _mpsToKmh(double value) => value * 3.6;
double _mphToMps(double value) => value * 0.44704;
double _mpsToMph(double value) => value / 0.44704;
double _barToPa(double value) => value * 100000;
double _paToBar(double value) => value / 100000;
double _psiToPa(double value) => value * 6894.75729;
double _paToPsi(double value) => value / 6894.75729;
double _kiloToBase(double value) => value * 1000;
double _baseToKilo(double value) => value / 1000;
double _whToJoule(double value) => value * 3600;
double _jouleToWh(double value) => value / 3600;
double _kwhToJoule(double value) => value * 3600000;
double _jouleToKwh(double value) => value / 3600000;
double _hpToW(double value) => value * 745.699872;
double _wToHp(double value) => value / 745.699872;
double _radToDeg(double value) => value * 180 / math.pi;
double _degToRad(double value) => value * math.pi / 180;
double _gbToMb(double value) => value * 1024;
double _mbToGb(double value) => value / 1024;
double _tbToMb(double value) => value * 1024 * 1024;
double _mbToTb(double value) => value / (1024 * 1024);
double _ampToMilliAmp(double value) => value * 1000;
double _milliAmpToAmp(double value) => value / 1000;
double _voltToMilliVolt(double value) => value * 1000;
double _milliVoltToVolt(double value) => value / 1000;
