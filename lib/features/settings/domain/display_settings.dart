class DisplaySettings {
  const DisplaySettings({
    required this.decimalDigits,
    required this.useGrouping,
    required this.tapeKeySoundEnabled,
  });

  factory DisplaySettings.initial() => const DisplaySettings(
    decimalDigits: 2,
    useGrouping: true,
    tapeKeySoundEnabled: false,
  );

  final int decimalDigits;
  final bool useGrouping;
  final bool tapeKeySoundEnabled;

  DisplaySettings copyWith({
    int? decimalDigits,
    bool? useGrouping,
    bool? tapeKeySoundEnabled,
  }) {
    return DisplaySettings(
      decimalDigits: decimalDigits ?? this.decimalDigits,
      useGrouping: useGrouping ?? this.useGrouping,
      tapeKeySoundEnabled: tapeKeySoundEnabled ?? this.tapeKeySoundEnabled,
    );
  }
}
