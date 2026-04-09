import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
          _SectionCard(
            title: 'Genel',
            children: [
              SwitchListTile(
                title: const Text('Binlik Ayırıcı Kullan'),
                subtitle: const Text('Kapalı olursa sayı düz yazılır.'),
                value: state.useGrouping,
                onChanged: controller.toggleGrouping,
              ),
            ],
          ),
          _SectionCard(
            title: 'Standart',
            children: [
              _StepperTile(
                title: 'Ondalık Hane (0-8)',
                valueText: '${state.decimalDigits}',
                onMinus: () =>
                    controller.setDecimalDigits(state.decimalDigits - 1),
                onPlus: () =>
                    controller.setDecimalDigits(state.decimalDigits + 1),
              ),
            ],
          ),
          _SectionCard(
            title: 'Şerit',
            children: [
              SwitchListTile(
                title: const Text('Şerit Tuş Sesi'),
                subtitle: const Text('Eski tuş sesi benzeri click efekti.'),
                value: state.tapeKeySoundEnabled,
                onChanged: controller.toggleTapeKeySound,
              ),
              SwitchListTile(
                title: const Text('Şerit Save Modu'),
                subtitle: const Text(
                  'Snapshot kaydet/aç menüsünü etkin tutar.',
                ),
                value: state.tapeSaveModeEnabled,
                onChanged: controller.toggleTapeSaveMode,
              ),
              _StepperTile(
                title: 'Şerit Tuş Yüksekliği',
                valueText: '${state.tapeKeyHeight}px',
                onMinus: () =>
                    controller.setTapeKeyHeight(state.tapeKeyHeight - 1),
                onPlus: () =>
                    controller.setTapeKeyHeight(state.tapeKeyHeight + 1),
                width: 170,
              ),
              ListTile(
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
              ListTile(
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
            ],
          ),
          _SectionCard(
            title: 'Finans',
            children: [
              _StepperTile(
                title: 'KDV Oranı (%)',
                valueText: '%${state.vatRatePercent}',
                onMinus: () =>
                    controller.setVatRatePercent(state.vatRatePercent - 1),
                onPlus: () =>
                    controller.setVatRatePercent(state.vatRatePercent + 1),
              ),
            ],
          ),
          _SectionCard(
            title: 'Piyasa',
            children: [
              _StepperTile(
                title: 'Piyasa Float',
                valueText: '${state.marketPriceDigits}',
                onMinus: () => controller.setMarketPriceDigits(
                  state.marketPriceDigits - 1,
                ),
                onPlus: () => controller.setMarketPriceDigits(
                  state.marketPriceDigits + 1,
                ),
              ),
              ListTile(
                title: Text(
                  'Hisse Kodlari (en fazla $maxMarketStockSymbols)',
                ),
                subtitle: Text(
                  state.marketStockSymbols.isEmpty
                      ? 'Hisse kodu eklenmedi.'
                      : state.marketStockSymbols.join(', '),
                ),
                trailing: IconButton(
                  onPressed: () =>
                      _showStockSymbolsSheet(context, controller, state),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ],
          ),
          _SectionCard(
            title: 'Haber',
            children: [
              ListTile(
                title: const Text('Piyasa Haber Kaynakları'),
                subtitle: Text(
                  state.marketNewsSources.isEmpty
                      ? 'Kaynak eklenmedi.'
                      : state.marketNewsSources.join('\n'),
                ),
                trailing: IconButton(
                  onPressed: () =>
                      _showNewsSourcesSheet(context, controller, state),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showStockSymbolsSheet(
    BuildContext context,
    DisplaySettingsController controller,
    DisplaySettings state,
  ) {
    final textController = TextEditingController(
      text: state.marketStockSymbols.join('\n'),
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Her satira bir hisse kodu girin',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Ornek: THYAO, ASELS, TUPRS, AAPL, NVDA. Virgulle, boslukla veya satir satir girebilirsin. Sistem once BIST/Bigpara, olmazsa yurtdisi kaynagini dener. En fazla $maxMarketStockSymbols kod kaydedilir.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                minLines: 10,
                maxLines: 14,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'THYAO\nASELS\nTUPRS\nAAPL\nNVDA',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  try {
                    await controller.setMarketStockSymbols(
                      textController.text.split('\n'),
                    );
                    if (!sheetContext.mounted || !context.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Hisse listesi kaydedildi.'),
                      ),
                    );
                  } catch (_) {
                    if (!sheetContext.mounted) return;
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Hisse listesi kaydedilemedi.'),
                      ),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNewsSourcesSheet(
    BuildContext context,
    DisplaySettingsController controller,
    DisplaySettings state,
  ) {
    final textController = TextEditingController(
      text: state.marketNewsSources.join('\n'),
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Her satira bir haber kaynagi URL girin',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Bigpara RSS'),
                    onPressed: () {
                      textController.text = _appendUrl(
                        textController.text,
                        'https://bigpara.hurriyet.com.tr/rss/',
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.open_in_browser_outlined),
                title: const Text('RSS rehberini webde ac'),
                subtitle: const Text(
                  'Uygun kaynagi secip kopyalayin, sonra asagidaki alana yapistirin.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openExternalGuide(context),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'https://bigpara.hurriyet.com.tr/rss/',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  try {
                    await controller.setMarketNewsSources(
                      textController.text.split('\n'),
                    );
                    if (!sheetContext.mounted || !context.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Haber kaynaklari kaydedildi.'),
                      ),
                    );
                  } catch (_) {
                    if (!sheetContext.mounted) return;
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(
                        content: Text('Haber kaynaklari kaydedilemedi.'),
                      ),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _appendUrl(String current, String url) {
    final lines = current
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (!lines.contains(url)) {
      lines.add(url);
    }
    return lines.join('\n');
  }

  Future<void> _openExternalGuide(BuildContext context) async {
    final uri = Uri.parse(
      'https://github.com/bakinazik/rss?tab=readme-ov-file#ekonomi-ve-finans',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rehber baglantisi acilamadi.')),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 12),
            ..._withDividers(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final output = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      output.add(items[i]);
      if (i != items.length - 1) {
        output.add(const Divider(height: 1));
      }
    }
    return output;
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.title,
    required this.valueText,
    required this.onMinus,
    required this.onPlus,
    this.width = 140,
  });

  final String title;
  final String valueText;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text('Mevcut: $valueText'),
      trailing: SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: onMinus,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(valueText),
            IconButton(
              onPressed: onPlus,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}
