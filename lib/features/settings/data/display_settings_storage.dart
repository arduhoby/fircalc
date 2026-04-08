import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/display_settings.dart';

class DisplaySettingsStorage {
  Future<DisplaySettings?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DisplaySettings(
        decimalDigits: (map['decimalDigits'] as num?)?.toInt() ?? 2,
        useGrouping: map['useGrouping'] as bool? ?? true,
        tapeKeySoundEnabled: map['tapeKeySoundEnabled'] as bool? ?? true,
        vatRatePercent: (map['vatRatePercent'] as num?)?.toInt() ?? 18,
        tapeSaveModeEnabled: map['tapeSaveModeEnabled'] as bool? ?? false,
        tapeKeyHeight: ((map['tapeKeyHeight'] as num?)?.toInt() ?? 50).clamp(
          44,
          58,
        ),
        tapeAuxLeft: _auxFrom(map['tapeAuxLeft'] as String?),
        tapeAuxRight: _auxFrom(map['tapeAuxRight'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DisplaySettings settings) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final data = <String, dynamic>{
      'decimalDigits': settings.decimalDigits,
      'useGrouping': settings.useGrouping,
      'tapeKeySoundEnabled': settings.tapeKeySoundEnabled,
      'vatRatePercent': settings.vatRatePercent,
      'tapeSaveModeEnabled': settings.tapeSaveModeEnabled,
      'tapeKeyHeight': settings.tapeKeyHeight,
      'tapeAuxLeft': settings.tapeAuxLeft.name,
      'tapeAuxRight': settings.tapeAuxRight.name,
    };
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  TapeAuxKeyOption _auxFrom(String? name) {
    if (name == null) return TapeAuxKeyOption.dollar;
    return TapeAuxKeyOption.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TapeAuxKeyOption.dollar,
    );
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'display_settings.json'));
  }
}
