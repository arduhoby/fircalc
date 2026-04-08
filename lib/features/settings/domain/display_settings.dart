enum TapeAuxKeyOption { none, dollar, e, ampersand }

extension TapeAuxKeyOptionX on TapeAuxKeyOption {
  String get label => switch (this) {
    TapeAuxKeyOption.none => 'Boş',
    TapeAuxKeyOption.dollar => r'$',
    TapeAuxKeyOption.e => 'E',
    TapeAuxKeyOption.ampersand => '&',
  };
}

class DisplaySettings {
  const DisplaySettings({
    required this.decimalDigits,
    required this.useGrouping,
    required this.tapeKeySoundEnabled,
    required this.vatRatePercent,
    required this.tapeSaveModeEnabled,
    required this.tapeKeyHeight,
    required this.tapeAuxLeft,
    required this.tapeAuxRight,
  });

  factory DisplaySettings.initial() => const DisplaySettings(
    decimalDigits: 2,
    useGrouping: true,
    tapeKeySoundEnabled: true,
    vatRatePercent: 18,
    tapeSaveModeEnabled: false,
    tapeKeyHeight: 50,
    tapeAuxLeft: TapeAuxKeyOption.dollar,
    tapeAuxRight: TapeAuxKeyOption.e,
  );

  final int decimalDigits;
  final bool useGrouping;
  final bool tapeKeySoundEnabled;
  final int vatRatePercent;
  final bool tapeSaveModeEnabled;
  final int tapeKeyHeight;
  final TapeAuxKeyOption tapeAuxLeft;
  final TapeAuxKeyOption tapeAuxRight;

  DisplaySettings copyWith({
    int? decimalDigits,
    bool? useGrouping,
    bool? tapeKeySoundEnabled,
    int? vatRatePercent,
    bool? tapeSaveModeEnabled,
    int? tapeKeyHeight,
    TapeAuxKeyOption? tapeAuxLeft,
    TapeAuxKeyOption? tapeAuxRight,
  }) {
    return DisplaySettings(
      decimalDigits: decimalDigits ?? this.decimalDigits,
      useGrouping: useGrouping ?? this.useGrouping,
      tapeKeySoundEnabled: tapeKeySoundEnabled ?? this.tapeKeySoundEnabled,
      vatRatePercent: vatRatePercent ?? this.vatRatePercent,
      tapeSaveModeEnabled: tapeSaveModeEnabled ?? this.tapeSaveModeEnabled,
      tapeKeyHeight: tapeKeyHeight ?? this.tapeKeyHeight,
      tapeAuxLeft: tapeAuxLeft ?? this.tapeAuxLeft,
      tapeAuxRight: tapeAuxRight ?? this.tapeAuxRight,
    );
  }
}
