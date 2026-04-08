import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/number_display_formatter.dart';
import '../../../core/widgets/calc_key_button.dart';
import '../../settings/application/display_settings_controller.dart';
import '../../settings/domain/display_settings.dart';
import '../application/standard_calculator_controller.dart';
import '../domain/standard_calculator_state.dart';

class StandardCalculatorScreen extends ConsumerWidget {
  const StandardCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(standardCalculatorControllerProvider);
    final controller = ref.read(standardCalculatorControllerProvider.notifier);
    final settings = ref.watch(displaySettingsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final formattedDisplay = NumberDisplayFormatter.format(
      raw: state.display,
      locale: locale,
      settings: settings,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      formattedDisplay,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _MemoryBar(
              state: state,
              controller: controller,
              settings: settings,
              locale: locale,
            ),
            const SizedBox(height: 8),
            _Keypad(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _MemoryBar extends StatelessWidget {
  const _MemoryBar({
    required this.state,
    required this.controller,
    required this.settings,
    required this.locale,
  });

  final StandardCalculatorState state;
  final StandardCalculatorController controller;
  final DisplaySettings settings;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MemorySlot.values.map((slot) {
        final v = state.memories[slot];
        final isFilled = v != null;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.memoryRecall(slot),
            onLongPress: () {
              final raw = v?.toString() ?? '-';
              final text = v == null
                  ? raw
                  : NumberDisplayFormatter.format(
                      raw: raw,
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

class _Keypad extends StatelessWidget {
  const _Keypad({required this.controller});

  final StandardCalculatorController controller;

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

  void _tap(String key) {
    switch (key) {
      case 'C':
        controller.clear();
      case 'CE':
        controller.clearEntry();
      case '%':
        controller.percent();
      case '÷':
        controller.operation(CalcOperator.divide);
      case '×':
        controller.operation(CalcOperator.multiply);
      case '-':
        controller.operation(CalcOperator.subtract);
      case '+':
        controller.operation(CalcOperator.add);
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
