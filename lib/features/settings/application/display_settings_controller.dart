import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/display_settings_storage.dart';
import '../domain/display_settings.dart';

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsController, DisplaySettings>(
      DisplaySettingsController.new,
    );

class DisplaySettingsController extends Notifier<DisplaySettings> {
  late final DisplaySettingsStorage _storage;
  var _restoreStarted = false;
  var _mutationVersion = 0;

  @override
  DisplaySettings build() {
    _storage = DisplaySettingsStorage();
    _restoreIfAny();
    return DisplaySettings.initial();
  }

  void _restoreIfAny() {
    if (_restoreStarted) return;
    _restoreStarted = true;
    final restoreVersion = _mutationVersion;
    unawaited(() async {
      final loaded = await _storage.load();
      if (loaded == null || !ref.mounted) return;
      if (_mutationVersion != restoreVersion) return;
      state = loaded;
    }());
  }

  Future<void> _mutate(
    DisplaySettings Function(DisplaySettings current) reducer,
  ) async {
    _mutationVersion += 1;
    final nextState = reducer(state);
    state = nextState;
    await _storage.save(nextState);
  }

  void setDecimalDigits(int digits) {
    final safe = digits.clamp(0, 8);
    unawaited(_mutate((current) => current.copyWith(decimalDigits: safe)));
  }

  void toggleGrouping(bool value) {
    unawaited(_mutate((current) => current.copyWith(useGrouping: value)));
  }

  void toggleTapeKeySound(bool value) {
    unawaited(
      _mutate((current) => current.copyWith(tapeKeySoundEnabled: value)),
    );
  }

  void setVatRatePercent(int value) {
    unawaited(
      _mutate(
        (current) => current.copyWith(vatRatePercent: value.clamp(0, 99)),
      ),
    );
  }

  void toggleTapeSaveMode(bool value) {
    unawaited(
      _mutate((current) => current.copyWith(tapeSaveModeEnabled: value)),
    );
  }

  void setTapeKeyHeight(int value) {
    unawaited(
      _mutate(
        (current) => current.copyWith(tapeKeyHeight: value.clamp(44, 58)),
      ),
    );
  }

  void setTapeAuxLeft(TapeAuxKeyOption value) {
    unawaited(_mutate((current) => current.copyWith(tapeAuxLeft: value)));
  }

  void setTapeAuxRight(TapeAuxKeyOption value) {
    unawaited(_mutate((current) => current.copyWith(tapeAuxRight: value)));
  }

  void setMarketPriceDigits(int value) {
    unawaited(
      _mutate(
        (current) => current.copyWith(marketPriceDigits: value.clamp(0, 4)),
      ),
    );
  }

  Future<void> setMarketStockSymbols(List<String> symbols) {
    final cleaned = symbols
        .expand((item) => item.split(RegExp(r'[\s,;]+')))
        .map((item) => item.trim().toUpperCase())
        .where((item) => item.isNotEmpty)
        .take(maxMarketStockSymbols)
        .toList();
    return _mutate((current) => current.copyWith(marketStockSymbols: cleaned));
  }

  Future<void> setMarketNewsSources(List<String> sources) {
    final cleaned = sources
        .expand((item) => item.split('\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return _mutate((current) => current.copyWith(marketNewsSources: cleaned));
  }
}
