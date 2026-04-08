import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/types/decimal_value.dart';
import '../data/tape_storage.dart';
import '../domain/tape_engine.dart';
import '../domain/tape_models.dart';

final tapeControllerProvider =
    NotifierProvider<TapeController, TapeSessionState>(TapeController.new);

class TapeController extends Notifier<TapeSessionState> {
  final _engine = TapeEngine();
  late final TapeStorage _storage;
  var _restoreStarted = false;

  @override
  TapeSessionState build() {
    _storage = ref.read(tapeStorageProvider);
    _restoreLatestIfAny();
    return TapeSessionState.initial();
  }

  void _restoreLatestIfAny() {
    if (_restoreStarted) return;
    _restoreStarted = true;
    unawaited(() async {
      final saved = await _storage.loadLatest();
      if (saved == null || !ref.mounted) return;
      state = saved;
    }());
  }

  void _mutate(TapeSessionState Function(TapeSessionState current) reducer) {
    state = reducer(state);
    unawaited(_storage.saveLatest(state));
  }

  void digit(String d) => _mutate((current) => _engine.inputDigit(current, d));
  void decimalPoint() => _mutate(_engine.inputDecimal);
  void toggleSign() => _mutate(_engine.toggleSign);
  void clearEntry() => _mutate(_engine.clearEntry);
  void backspace() => _mutate(_engine.backspace);
  void clearAll() => _mutate(_engine.clearAll);
  void clearAllMemories() => _mutate(_engine.clearAllMemories);
  void percent() => _mutate(_engine.percent);
  void vat({required String ratePercent, required TapeVatMode mode}) {
    _mutate(
      (current) => _engine.applyVat(
        current,
        rate: DecimalValue.parse(ratePercent),
        mode: mode,
      ),
    );
  }

  void applyEffectiveFxRate({
    required String currencyLabel,
    required String rate,
  }) {
    _mutate(
      (current) => _engine.applyEffectiveFxRate(
        current,
        currencyLabel: currencyLabel,
        rate: DecimalValue.parse(rate),
      ),
    );
  }

  void applyFormulaResult({
    required String expression,
    required String result,
  }) {
    _mutate(
      (current) => _engine.applyFormulaResult(
        current,
        expression: expression,
        result: DecimalValue.parse(result),
      ),
    );
  }

  void addPlus() {
    _mutate((current) {
      if (current.expressionBuffer.isNotEmpty) {
        return _engine.expressionOperator(current, '+');
      }
      var next = current;
      if (next.pendingOperation != null && next.pendingLeftOperand != null) {
        next = _engine.equals(next);
      }
      return _engine.addSignedLine(next, TapeLineSign.plus);
    });
  }

  void addMinus() {
    _mutate((current) {
      if (current.expressionBuffer.isNotEmpty) {
        return _engine.expressionOperator(current, '-');
      }
      var next = current;
      if (next.pendingOperation != null && next.pendingLeftOperand != null) {
        next = _engine.equals(next);
      }
      return _engine.addSignedLine(next, TapeLineSign.minus);
    });
  }

  void equals() => _mutate(_engine.equals);

  void startMultiply() => _mutate(
    (current) => current.expressionBuffer.isNotEmpty
        ? _engine.expressionOperator(current, '*')
        : _engine.startInterimOperation(current, TapePendingOperation.multiply),
  );
  void startDivide() => _mutate(
    (current) => current.expressionBuffer.isNotEmpty
        ? _engine.expressionOperator(current, '/')
        : _engine.startInterimOperation(current, TapePendingOperation.divide),
  );

  void leftParen() => _mutate(_engine.leftParen);
  void rightParen() => _mutate(_engine.rightParen);
  void power() => _mutate(_engine.power);
  void sqrt() => _mutate(_engine.sqrt);

  void addInterimAsPlus() => _mutate(
    (current) => _engine.addInterimResultToTape(current, TapeLineSign.plus),
  );
  void addInterimAsMinus() => _mutate(
    (current) => _engine.addInterimResultToTape(current, TapeLineSign.minus),
  );

  void memoryStore(TapeMemorySlot slot) =>
      _mutate((current) => _engine.memoryStore(current, slot));
  void memoryRecall(TapeMemorySlot slot) =>
      _mutate((current) => _engine.memoryRecall(current, slot));
  void memoryAdd(TapeMemorySlot slot) =>
      _mutate((current) => _engine.memoryAdd(current, slot));
  void memorySubtract(TapeMemorySlot slot) =>
      _mutate((current) => _engine.memorySubtract(current, slot));
  void memoryClear(TapeMemorySlot slot) =>
      _mutate((current) => _engine.memoryClear(current, slot));

  Future<String> saveSnapshotNow() => _storage.saveSnapshot(state);
  Future<List<TapeSnapshotInfo>> listSnapshots() => _storage.listSnapshots();
  Future<void> openSnapshot(int id) async {
    final loaded = await _storage.loadSnapshot(id);
    if (loaded == null || !ref.mounted) return;
    state = loaded;
    unawaited(_storage.saveLatest(state));
  }
}
