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
    final openParen = _openParenCount(state.expressionBuffer);
    final expressionPreview = _toDisplayExpression(state.expressionBuffer);
    final historyPreview = state.recentOperations.reversed
        .take(2)
        .toList()
        .reversed
        .map(_toDisplayExpression)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 72;
                      if (compact) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            formattedDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (historyPreview.isNotEmpty)
                            ...historyPreview.map(
                              (line) => Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  line,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ),
                            ),
                          if (historyPreview.isNotEmpty)
                            const SizedBox(height: 4),
                          if (expressionPreview.isNotEmpty || openParen > 0)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    expressionPreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                ),
                                Text(
                                  '(: $openParen',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.black54),
                                ),
                              ],
                            ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              formattedDisplay,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _MemoryRow(controller: controller, settings: settings),
            const SizedBox(height: 8),
            _Keypad(controller: controller, settings: settings),
          ],
        ),
      ),
    );
  }

  int _openParenCount(String expression) {
    var open = 0;
    var close = 0;
    for (final c in expression.split('')) {
      if (c == '(') open++;
      if (c == ')') close++;
    }
    final count = open - close;
    return count < 0 ? 0 : count;
  }

  String _toDisplayExpression(String expression) {
    if (expression.isEmpty) return '';
    return expression
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('sqrt', '√');
  }
}

class _MemoryRow extends StatelessWidget {
  const _MemoryRow({required this.controller, required this.settings});

  final StandardCalculatorController controller;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MemoryButton(
          label: 'M+',
          onTap: () => controller.memoryAdd(MemorySlot.m1),
          settings: settings,
        ),
        _MemoryButton(
          label: 'M-',
          onTap: () => controller.memorySubtract(MemorySlot.m1),
          settings: settings,
        ),
        _MemoryButton(
          label: 'MR',
          onTap: () => controller.memoryRecall(MemorySlot.m1),
          settings: settings,
        ),
        _MemoryButton(
          label: 'MC',
          onTap: () => controller.memoryClear(MemorySlot.m1),
          settings: settings,
        ),
      ],
    );
  }
}

class _MemoryButton extends StatelessWidget {
  const _MemoryButton({
    required this.label,
    required this.onTap,
    required this.settings,
  });

  final String label;
  final VoidCallback onTap;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: settings.tapeKeyHeight.toDouble(),
          child: CalcKeyButton(label: label, onTap: onTap),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.controller, required this.settings});

  final StandardCalculatorController controller;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    final labels = [
      ['(', ')', '√', '^', '⌫'],
      ['C', 'CE', '%', '÷', '×'],
      ['7', '8', '9', '-', '+'],
      ['4', '5', '6', '1', '2'],
      ['3', '0', '.', '±', '='],
    ];

    return Column(
      children: labels.map((row) {
        return Row(
          children: row.map((label) {
            final isOperator = [
              '÷',
              '×',
              '-',
              '+',
              '%',
              '^',
              '√',
            ].contains(label);
            final isEquals = label == '=';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  height: settings.tapeKeyHeight.toDouble(),
                  child: CalcKeyButton(
                    label: label,
                    isOperator: isOperator,
                    isEquals: isEquals,
                    onTap: () => _tap(label),
                  ),
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
      case '(':
        controller.leftParen();
      case ')':
        controller.rightParen();
      case '^':
        controller.power();
      case '√':
        controller.sqrt();
      case '⌫':
        controller.backspace();
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
