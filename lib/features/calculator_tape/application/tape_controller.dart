import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/tape_engine.dart';
import '../domain/tape_models.dart';

final tapeControllerProvider =
    NotifierProvider<TapeController, TapeSessionState>(TapeController.new);

class TapeController extends Notifier<TapeSessionState> {
  final _engine = TapeEngine();

  @override
  TapeSessionState build() => TapeSessionState.initial();

  void digit(String d) => state = _engine.inputDigit(state, d);
  void decimalPoint() => state = _engine.inputDecimal(state);
  void toggleSign() => state = _engine.toggleSign(state);
  void clearEntry() => state = _engine.clearEntry(state);
  void clearAll() => state = _engine.clearAll(state);
  void percent() => state = _engine.percent(state);
  void addPlus() => state = _engine.addSignedLine(state, TapeLineSign.plus);
  void addMinus() => state = _engine.addSignedLine(state, TapeLineSign.minus);
  void equals() => state = _engine.equals(state);

  void startMultiply() => state = _engine.startInterimOperation(
    state,
    TapePendingOperation.multiply,
  );
  void startDivide() =>
      state = _engine.startInterimOperation(state, TapePendingOperation.divide);

  void addInterimAsPlus() =>
      state = _engine.addInterimResultToTape(state, TapeLineSign.plus);
  void addInterimAsMinus() =>
      state = _engine.addInterimResultToTape(state, TapeLineSign.minus);

  void memoryStore(TapeMemorySlot slot) =>
      state = _engine.memoryStore(state, slot);
  void memoryRecall(TapeMemorySlot slot) =>
      state = _engine.memoryRecall(state, slot);
  void memoryAdd(TapeMemorySlot slot) => state = _engine.memoryAdd(state, slot);
  void memorySubtract(TapeMemorySlot slot) =>
      state = _engine.memorySubtract(state, slot);
  void memoryClear(TapeMemorySlot slot) =>
      state = _engine.memoryClear(state, slot);
}
