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

  @override
  DisplaySettings build() {
    _storage = DisplaySettingsStorage();
    _restoreIfAny();
    return DisplaySettings.initial();
  }

  void _restoreIfAny() {
    if (_restoreStarted) return;
    _restoreStarted = true;
    unawaited(() async {
      final loaded = await _storage.load();
      if (loaded == null || !ref.mounted) return;
      state = loaded.copyWith(tapeKeyHeight: 50);
    }());
  }

  void _mutate(DisplaySettings Function(DisplaySettings current) reducer) {
    state = reducer(state);
    unawaited(_storage.save(state));
  }

  void setDecimalDigits(int digits) {
    final safe = digits.clamp(0, 8);
    _mutate((current) => current.copyWith(decimalDigits: safe));
  }

  void toggleGrouping(bool value) {
    _mutate((current) => current.copyWith(useGrouping: value));
  }

  void toggleTapeKeySound(bool value) {
    _mutate((current) => current.copyWith(tapeKeySoundEnabled: value));
  }

  void setVatRatePercent(int value) {
    _mutate((current) => current.copyWith(vatRatePercent: value.clamp(0, 99)));
  }

  void toggleTapeSaveMode(bool value) {
    _mutate((current) => current.copyWith(tapeSaveModeEnabled: value));
  }

  void setTapeKeyHeight(int value) {
    _mutate((current) => current.copyWith(tapeKeyHeight: value.clamp(44, 58)));
  }

  void setTapeAuxLeft(TapeAuxKeyOption value) {
    _mutate((current) => current.copyWith(tapeAuxLeft: value));
  }

  void setTapeAuxRight(TapeAuxKeyOption value) {
    _mutate((current) => current.copyWith(tapeAuxRight: value));
  }
}
