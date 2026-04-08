import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/display_settings.dart';

final displaySettingsProvider =
    NotifierProvider<DisplaySettingsController, DisplaySettings>(
      DisplaySettingsController.new,
    );

class DisplaySettingsController extends Notifier<DisplaySettings> {
  @override
  DisplaySettings build() => DisplaySettings.initial();

  void setDecimalDigits(int digits) {
    final safe = digits.clamp(0, 8);
    state = state.copyWith(decimalDigits: safe);
  }

  void toggleGrouping(bool value) {
    state = state.copyWith(useGrouping: value);
  }

  void toggleTapeKeySound(bool value) {
    state = state.copyWith(tapeKeySoundEnabled: value);
  }
}
