import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/display_settings_controller.dart';
import '../domain/display_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(displaySettingsProvider);
    final controller = ref.read(displaySettingsProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Ondalık Hane (0-8)'),
              subtitle: Text('Mevcut: ${state.decimalDigits}'),
              trailing: SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () =>
                          controller.setDecimalDigits(state.decimalDigits - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${state.decimalDigits}'),
                    IconButton(
                      onPressed: () =>
                          controller.setDecimalDigits(state.decimalDigits + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Binlik Ayırıcı Kullan'),
              subtitle: const Text('Kapalı olursa sayı düz yazılır.'),
              value: state.useGrouping,
              onChanged: controller.toggleGrouping,
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Şerit Tuş Sesi'),
              subtitle: const Text('Eski tuş sesi benzeri click efekti.'),
              value: state.tapeKeySoundEnabled,
              onChanged: controller.toggleTapeKeySound,
            ),
          ),
          Card(
            child: SwitchListTile(
              title: const Text('Şerit Save Modu'),
              subtitle: const Text('Snapshot kaydet/aç menüsünü etkin tutar.'),
              value: state.tapeSaveModeEnabled,
              onChanged: controller.toggleTapeSaveMode,
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Şerit Tuş Yüksekliği'),
              subtitle: Text('Mevcut: ${state.tapeKeyHeight}px'),
              trailing: SizedBox(
                width: 160,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () =>
                          controller.setTapeKeyHeight(state.tapeKeyHeight - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${state.tapeKeyHeight}'),
                    IconButton(
                      onPressed: () =>
                          controller.setTapeKeyHeight(state.tapeKeyHeight + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('KDV Oranı (%)'),
              subtitle: Text('Mevcut: %${state.vatRatePercent}'),
              trailing: SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => controller.setVatRatePercent(
                        state.vatRatePercent - 1,
                      ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('%${state.vatRatePercent}'),
                    IconButton(
                      onPressed: () => controller.setVatRatePercent(
                        state.vatRatePercent + 1,
                      ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Şerit Özel Tuş Sol'),
              trailing: DropdownButton<TapeAuxKeyOption>(
                value: state.tapeAuxLeft,
                items: TapeAuxKeyOption.values
                    .map(
                      (e) => DropdownMenuItem<TapeAuxKeyOption>(
                        value: e,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  controller.setTapeAuxLeft(v);
                },
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Şerit Özel Tuş Sağ'),
              trailing: DropdownButton<TapeAuxKeyOption>(
                value: state.tapeAuxRight,
                items: TapeAuxKeyOption.values
                    .map(
                      (e) => DropdownMenuItem<TapeAuxKeyOption>(
                        value: e,
                        child: Text(e.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  controller.setTapeAuxRight(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
