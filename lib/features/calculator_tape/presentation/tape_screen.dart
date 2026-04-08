import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/number_display_formatter.dart';
import '../../../core/widgets/calc_key_button.dart';
import '../../settings/application/display_settings_controller.dart';
import '../../settings/domain/display_settings.dart';
import '../application/tape_controller.dart';
import '../domain/tape_models.dart';

class TapeScreen extends ConsumerWidget {
  const TapeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tapeControllerProvider);
    final controller = ref.read(tapeControllerProvider.notifier);
    final settings = ref.watch(displaySettingsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: _TapePaper(
                state: state,
                locale: locale,
                settings: settings,
              ),
            ),
            const SizedBox(height: 10),
            _TapeMemoryBar(
              state: state,
              controller: controller,
              locale: locale,
              settings: settings,
            ),
            const SizedBox(height: 8),
            _TapeKeypad(controller: controller, settings: settings),
          ],
        ),
      ),
    );
  }
}

class _TapePaper extends StatelessWidget {
  const _TapePaper({
    required this.state,
    required this.locale,
    required this.settings,
  });

  final TapeSessionState state;
  final String locale;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    final display = NumberDisplayFormatter.format(
      raw: state.inputBuffer,
      locale: locale,
      settings: settings,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE7E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.pendingExpression ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Text(
                  display,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Divider(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: state.lines.length < 8 ? 8 : state.lines.length,
                itemBuilder: (context, index) {
                  final line = index < state.lines.length
                      ? state.lines[index]
                      : null;
                  return SizedBox(
                    height: 38,
                    child: _TapeLineRow(
                      line: line,
                      locale: locale,
                      settings: settings,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapeLineRow extends StatelessWidget {
  const _TapeLineRow({
    required this.line,
    required this.locale,
    required this.settings,
  });

  final TapeLine? line;
  final String locale;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    if (line == null) return const SizedBox.shrink();

    final tapeLine = line!;
    final isSubtotal = tapeLine.kind == TapeLineKind.subtotal;
    final isGrandTotal = tapeLine.kind == TapeLineKind.grandTotal;

    final leftLabel = switch (tapeLine.kind) {
      TapeLineKind.subtotal => 'Ara Toplam',
      TapeLineKind.grandTotal => 'Genel Toplam',
      _ => '',
    };

    final signPrefix = tapeLine.kind == TapeLineKind.normal
        ? (tapeLine.sign == TapeLineSign.plus ? '+' : '-')
        : '';

    final formatted = NumberDisplayFormatter.format(
      raw: tapeLine.amount.toString(),
      locale: locale,
      settings: settings,
    );

    final isNegative =
        tapeLine.sign == TapeLineSign.minus || formatted.startsWith('-');

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black54,
            width: isGrandTotal ? 2 : (isSubtotal ? 1 : 0),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 102,
            child: Text(
              leftLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$signPrefix$formatted',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isNegative
                    ? const Color(0xFFB00020)
                    : const Color(0xFF1C1C1E),
                fontWeight: isSubtotal || isGrandTotal
                    ? FontWeight.w700
                    : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TapeMemoryBar extends StatelessWidget {
  const _TapeMemoryBar({
    required this.state,
    required this.controller,
    required this.locale,
    required this.settings,
  });

  final TapeSessionState state;
  final TapeController controller;
  final String locale;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TapeMemorySlot.values.map((slot) {
        final value = state.memories[slot];
        final isFilled = value != null;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.memoryRecall(slot),
            onLongPress: () {
              final text = value == null
                  ? '-'
                  : NumberDisplayFormatter.format(
                      raw: value.toString(),
                      locale: locale,
                      settings: settings,
                    );
              showCupertinoModalPopup<void>(
                context: context,
                builder: (context) => CupertinoActionSheet(
                  title: Text(slot.name.toUpperCase()),
                  message: Text(text),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () {
                        controller.memoryStore(slot);
                        Navigator.pop(context);
                      },
                      child: const Text('MS'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        controller.memoryAdd(slot);
                        Navigator.pop(context);
                      },
                      child: const Text('M+'),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        controller.memorySubtract(slot);
                        Navigator.pop(context);
                      },
                      child: const Text('M-'),
                    ),
                    CupertinoActionSheetAction(
                      isDestructiveAction: true,
                      onPressed: () {
                        controller.memoryClear(slot);
                        Navigator.pop(context);
                      },
                      child: const Text('MC'),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                ),
              );
            },
            child: Card(
              color: isFilled
                  ? const Color(0xFFE7F0FF)
                  : const Color(0xFFF1F2F5),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    slot.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: isFilled ? FontWeight.w700 : FontWeight.w500,
                      color: isFilled
                          ? const Color(0xFF0A84FF)
                          : Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TapeKeypad extends StatelessWidget {
  const _TapeKeypad({required this.controller, required this.settings});

  final TapeController controller;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    final labels = [
      ['C', 'CE', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['±', '0', '.', '='],
    ];

    return Column(
      children: labels.map((row) {
        return Row(
          children: row.map((label) {
            final isOperator = ['÷', '×', '-', '+', '%'].contains(label);
            final isEquals = label == '=';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CalcKeyButton(
                  label: label,
                  isOperator: isOperator,
                  isEquals: isEquals,
                  onTap: () => _tap(label),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  void _playSound() {
    if (settings.tapeKeySoundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  void _tap(String key) {
    _playSound();
    switch (key) {
      case 'C':
        controller.clearAll();
      case 'CE':
        controller.clearEntry();
      case '%':
        controller.percent();
      case '÷':
        controller.startDivide();
      case '×':
        controller.startMultiply();
      case '-':
        controller.addMinus();
      case '+':
        controller.addPlus();
      case '=':
        controller.equals();
      case '±':
        controller.toggleSign();
      case '.':
        controller.decimalPoint();
      default:
        controller.digit(key);
    }
  }
}
