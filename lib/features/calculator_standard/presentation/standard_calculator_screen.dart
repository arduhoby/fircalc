import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/number_display_formatter.dart';
import '../../../core/widgets/calc_key_button.dart';
import '../../settings/application/display_settings_controller.dart';
import '../../settings/domain/display_settings.dart';
import '../application/standard_calculator_controller.dart';
import '../domain/standard_calculator_engine.dart';
import '../domain/standard_calculator_state.dart';

enum _ConvertToolMode {
  length,
  area,
  volume,
  weight,
  time,
  temperature,
  speed,
  pressure,
  energy,
  power,
  angle,
  data,
  electricUnit,
  electricOhm,
  electricPower,
  dateDifference,
}

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            const keypadGap = 8.0;
            const keypadRows = 6;
            final keypadHeight =
                (keypadRows * settings.tapeKeyHeight.toDouble()) +
                ((keypadRows - 1) * keypadGap);
            final memoryHeight = settings.tapeKeyHeight.toDouble() + 8;
            final topMinHeight = math.max(
              120.0,
              constraints.maxHeight - keypadHeight - memoryHeight - 16,
            );

            return Column(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: topMinHeight),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
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
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black54),
                                      ),
                                    ),
                                  ),
                                if (historyPreview.isNotEmpty)
                                  const SizedBox(height: 4),
                                if (expressionPreview.isNotEmpty ||
                                    openParen > 0)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          expressionPreview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.black54),
                                        ),
                                      ),
                                      Text(
                                        '(: $openParen',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    formattedDisplay,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _MemoryRow(controller: controller, settings: settings),
                const SizedBox(height: keypadGap),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    height: keypadHeight,
                    child: _Keypad(controller: controller, settings: settings),
                  ),
                ),
              ],
            );
          },
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
    const specs = [
      _StandardKeySpec(label: 'F1', row: 0, col: 0),
      _StandardKeySpec(label: 'CNV', row: 0, col: 1),
      _StandardKeySpec(label: 'SQR', row: 0, col: 2),
      _StandardKeySpec(label: 'RND', row: 0, col: 3),
      _StandardKeySpec(label: '⌫', row: 0, col: 4),
      _StandardKeySpec(label: '(', row: 1, col: 0),
      _StandardKeySpec(label: ')', row: 1, col: 1),
      _StandardKeySpec(label: '√', row: 1, col: 2),
      _StandardKeySpec(label: '^', row: 1, col: 3),
      _StandardKeySpec(label: '%', row: 1, col: 4),
      _StandardKeySpec(label: 'C', row: 2, col: 0),
      _StandardKeySpec(label: 'CE', row: 2, col: 1),
      _StandardKeySpec(label: '7', row: 2, col: 2),
      _StandardKeySpec(label: '8', row: 2, col: 3),
      _StandardKeySpec(label: '9', row: 2, col: 4),
      _StandardKeySpec(label: '4', row: 3, col: 0),
      _StandardKeySpec(label: '5', row: 3, col: 1),
      _StandardKeySpec(label: '6', row: 3, col: 2),
      _StandardKeySpec(label: '×', row: 3, col: 3),
      _StandardKeySpec(label: '÷', row: 3, col: 4),
      _StandardKeySpec(label: '1', row: 4, col: 0),
      _StandardKeySpec(label: '2', row: 4, col: 1),
      _StandardKeySpec(label: '3', row: 4, col: 2),
      _StandardKeySpec(label: '+', row: 4, col: 3),
      _StandardKeySpec(label: '-', row: 4, col: 4),
      _StandardKeySpec(label: '0', row: 5, col: 0),
      _StandardKeySpec(label: '.', row: 5, col: 1),
      _StandardKeySpec(label: '±', row: 5, col: 2),
      _StandardKeySpec(label: '=', row: 5, col: 3, colSpan: 2),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 5;
        const rows = 6;
        const gap = 8.0;
        final preferredKeyHeight = settings.tapeKeyHeight.toDouble();
        final keyWidth = (constraints.maxWidth - ((cols - 1) * gap)) / cols;
        final keyHeight = ((constraints.maxHeight - ((rows - 1) * gap)) / rows)
            .clamp(36.0, preferredKeyHeight);
        final totalHeight = (rows * keyHeight) + ((rows - 1) * gap);

        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: specs.map((spec) {
              final left = spec.col * (keyWidth + gap);
              final top = spec.row * (keyHeight + gap);
              final width =
                  (spec.colSpan * keyWidth) + ((spec.colSpan - 1) * gap);
              final height = keyHeight;
              final isOperator = [
                '÷',
                '×',
                '-',
                '+',
                '%',
                '^',
                '√',
                'SQR',
                'RND',
                'F1',
                'CNV',
                '±',
              ].contains(spec.label);
              final isEquals = spec.label == '=';

              return Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: CalcKeyButton(
                  label: spec.label,
                  isOperator: isOperator,
                  isEquals: isEquals,
                  onTap: () => _tap(context, spec.label),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _tap(BuildContext context, String key) {
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
      case 'SQR':
        _showSquareDialog(context);
      case 'RND':
        _showRandomDialog(context);
      case 'F1':
        _showMessage(context, '$key ayarlardan tanimlanacak.');
      case 'CNV':
        _showConvertDialog(context);
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

  Future<void> _showSquareDialog(BuildContext context) async {
    final radiusController = TextEditingController();
    final shortSideController = TextEditingController();
    final longSideController = TextEditingController();
    final latLonControllers = List.generate(
      3,
      (_) => (lat: TextEditingController(), lon: TextEditingController()),
    );
    var mode = _SquareMode.circle;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('SQR Alan Hesabı'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<_SquareMode>(
                      segments: const [
                        ButtonSegment<_SquareMode>(
                          value: _SquareMode.circle,
                          label: Text('Daire'),
                        ),
                        ButtonSegment<_SquareMode>(
                          value: _SquareMode.rectangle,
                          label: Text('Dikdortgen'),
                        ),
                        ButtonSegment<_SquareMode>(
                          value: _SquareMode.latLon,
                          label: Text('Lat/Lon'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          mode = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (mode == _SquareMode.circle)
                      TextField(
                        controller: radiusController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Yarıçap (r)',
                          border: OutlineInputBorder(),
                        ),
                      )
                    else if (mode == _SquareMode.rectangle)
                      Column(
                        children: [
                          TextField(
                            controller: shortSideController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Kisa kenar',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: longSideController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Uzun kenar',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'En az 3 nokta girin. 4 nokta ve uzeri daha dogru alan verir.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(latLonControllers.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: latLonControllers[index].lat,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                            signed: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: 'Lat ${index + 1}',
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: latLonControllers[index].lon,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                            signed: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: 'Lon ${index + 1}',
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  latLonControllers.add((
                                    lat: TextEditingController(),
                                    lon: TextEditingController(),
                                  ));
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: Text(
                                '${latLonControllers.length + 1}. nokta ekle',
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (mode == _SquareMode.circle) {
                      final radius = _tryParseNumber(radiusController.text);
                      if (radius == null || radius < 0) {
                        _showMessage(dialogContext, 'Geçerli bir yarıçap gir.');
                        return;
                      }
                      controller.circleArea(radius);
                    } else if (mode == _SquareMode.rectangle) {
                      final shortSide = _tryParseNumber(
                        shortSideController.text,
                      );
                      final longSide = _tryParseNumber(longSideController.text);
                      if (shortSide == null ||
                          longSide == null ||
                          shortSide <= 0 ||
                          longSide <= 0) {
                        _showMessage(
                          dialogContext,
                          'Kisa ve uzun kenari pozitif gir.',
                        );
                        return;
                      }
                      controller.rectangleArea(
                        shortSide: shortSide,
                        longSide: longSide,
                      );
                    } else {
                      final points = <LatLonPoint>[];
                      for (final pointController in latLonControllers) {
                        final lat = _tryParseNumber(pointController.lat.text);
                        final lon = _tryParseNumber(pointController.lon.text);
                        if (lat == null || lon == null) {
                          _showMessage(
                            dialogContext,
                            'Tum lat/lon noktalarini eksiksiz gir.',
                          );
                          return;
                        }
                        points.add(LatLonPoint(latitude: lat, longitude: lon));
                      }
                      controller.latLonArea(points);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Hesapla'),
                ),
              ],
            );
          },
        );
      },
    );

    radiusController.dispose();
    shortSideController.dispose();
    longSideController.dispose();
    for (final controller in latLonControllers) {
      controller.lat.dispose();
      controller.lon.dispose();
    }
  }

  Future<void> _showRandomDialog(BuildContext context) async {
    final minController = TextEditingController(text: '0');
    final maxController = TextEditingController(text: '100');
    final countController = TextEditingController(text: '5');
    final stepController = TextEditingController(text: '1');
    final precisionController = TextEditingController(text: '0');
    var allowFloat = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('RND Üret'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: minController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Minimum',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: maxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Maksimum',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Adet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stepController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: false,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Atlama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Float üret'),
                      subtitle: const Text('Sonuçlar tekrarsız üretilir'),
                      value: allowFloat,
                      onChanged: (value) {
                        setState(() {
                          allowFloat = value;
                        });
                      },
                    ),
                    if (allowFloat) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: precisionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ondalık basamak',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    final min = _tryParseNumber(minController.text);
                    final max = _tryParseNumber(maxController.text);
                    final count = int.tryParse(countController.text.trim());
                    final step = _tryParseNumber(stepController.text);
                    final decimalDigits = allowFloat
                        ? int.tryParse(precisionController.text.trim())
                        : 0;

                    if (min == null ||
                        max == null ||
                        count == null ||
                        step == null ||
                        decimalDigits == null) {
                      _showMessage(
                        dialogContext,
                        'Tüm alanları geçerli doldur.',
                      );
                      return;
                    }

                    controller.random(
                      RandomGenerationRequest(
                        min: min,
                        max: max,
                        count: count,
                        step: step,
                        allowFloat: allowFloat,
                        decimalDigits: decimalDigits,
                      ),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Üret'),
                ),
              ],
            );
          },
        );
      },
    );

    minController.dispose();
    maxController.dispose();
    countController.dispose();
    stepController.dispose();
    precisionController.dispose();
  }

  Future<void> _showConvertDialog(BuildContext context) async {
    final valueController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final ohmVoltageController = TextEditingController();
    final ohmCurrentController = TextEditingController();
    final ohmResistanceController = TextEditingController();
    final powerController = TextEditingController();
    final powerVoltageController = TextEditingController();
    final powerCurrentController = TextEditingController();
    startDateController.text = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String()
        .substring(0, 10);
    endDateController.text = DateTime.now().toIso8601String().substring(0, 10);
    var mode = _ConvertToolMode.length;
    var fromUnit = _unitsForMode(_ConvertToolMode.length).first;
    var toUnit = _unitsForMode(_ConvertToolMode.length).length > 1
        ? _unitsForMode(_ConvertToolMode.length)[1]
        : _unitsForMode(_ConvertToolMode.length).first;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentUnits = _unitsForMode(mode);
            if (currentUnits.isNotEmpty && !currentUnits.contains(fromUnit)) {
              fromUnit = currentUnits.first;
            }
            if (currentUnits.isNotEmpty && !currentUnits.contains(toUnit)) {
              toUnit = currentUnits.length > 1
                  ? currentUnits[1]
                  : currentUnits.first;
            }
            final conversionPreview = _buildConversionPreview(
              rawValue: valueController.text,
              fromUnit: fromUnit,
              toUnit: toUnit,
              enabled: _isUnitMode(mode),
            );
            final ohmPreview = _buildOhmPreview(
              voltage: _tryParseNumber(ohmVoltageController.text),
              current: _tryParseNumber(ohmCurrentController.text),
              resistance: _tryParseNumber(ohmResistanceController.text),
            );
            final powerPreview = _buildElectricPowerPreview(
              power: _tryParseNumber(powerController.text),
              voltage: _tryParseNumber(powerVoltageController.text),
              current: _tryParseNumber(powerCurrentController.text),
            );
            final datePreview = _buildDatePreview(
              start: DateTime.tryParse(startDateController.text),
              end: DateTime.tryParse(endDateController.text),
            );

            return AlertDialog(
              title: const Text('Donusturucu'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<_ConvertToolMode>(
                        initialValue: mode,
                        items: _ConvertToolMode.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(_convertModeLabel(item)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => mode = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isUnitMode(mode))
                        _buildConvertUnitSection(
                          valueController: valueController,
                          units: currentUnits,
                          fromUnit: fromUnit,
                          toUnit: toUnit,
                          preview: conversionPreview,
                          onChanged: () => setState(() {}),
                          onFromChanged: (value) =>
                              setState(() => fromUnit = value),
                          onToChanged: (value) =>
                              setState(() => toUnit = value),
                        ),
                      if (mode == _ConvertToolMode.electricOhm)
                        _buildOhmLawSection(
                          voltageController: ohmVoltageController,
                          currentController: ohmCurrentController,
                          resistanceController: ohmResistanceController,
                          preview: ohmPreview,
                          onTextChanged: () => setState(() {}),
                        ),
                      if (mode == _ConvertToolMode.electricPower)
                        _buildElectricPowerSection(
                          powerController: powerController,
                          voltageController: powerVoltageController,
                          currentController: powerCurrentController,
                          preview: powerPreview,
                          onTextChanged: () => setState(() {}),
                        ),
                      if (mode == _ConvertToolMode.dateDifference)
                        _buildDateDifferenceSection(
                          startDateController: startDateController,
                          endDateController: endDateController,
                          preview: datePreview,
                          onTextChanged: () => setState(() {}),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Kapat'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = _tryParseNumber(valueController.text);
                    if (_isUnitMode(mode) && value != null) {
                      controller.convertUnit(
                        from: fromUnit,
                        to: toUnit,
                        value: value,
                      );
                    }

                    final ohmVoltage = _tryParseNumber(
                      ohmVoltageController.text,
                    );
                    final ohmCurrent = _tryParseNumber(
                      ohmCurrentController.text,
                    );
                    final ohmResistance = _tryParseNumber(
                      ohmResistanceController.text,
                    );
                    if (mode == _ConvertToolMode.electricOhm &&
                        [
                          ohmVoltage,
                          ohmCurrent,
                          ohmResistance,
                        ].whereType<double>().length ==
                        2) {
                      final target = _resolveOhmTarget(
                        voltage: ohmVoltage,
                        current: ohmCurrent,
                        resistance: ohmResistance,
                      );
                      if (target != null) {
                      controller.electricOhmLaw(
                        target: target,
                        voltage: ohmVoltage,
                        current: ohmCurrent,
                        resistance: ohmResistance,
                      );
                      }
                    }

                    final power = _tryParseNumber(powerController.text);
                    final powerVoltage = _tryParseNumber(
                      powerVoltageController.text,
                    );
                    final powerCurrent = _tryParseNumber(
                      powerCurrentController.text,
                    );
                    if (mode == _ConvertToolMode.electricPower &&
                        [
                          power,
                          powerVoltage,
                          powerCurrent,
                        ].whereType<double>().length ==
                        2) {
                      final target = _resolvePowerTarget(
                        power: power,
                        voltage: powerVoltage,
                        current: powerCurrent,
                      );
                      if (target != null) {
                      controller.electricPower(
                        target: target,
                        power: power,
                        voltage: powerVoltage,
                        current: powerCurrent,
                      );
                      }
                    }

                    final start = DateTime.tryParse(startDateController.text);
                    final end = DateTime.tryParse(endDateController.text);
                    if (mode == _ConvertToolMode.dateDifference &&
                        start != null &&
                        end != null) {
                      final result = controller.calculateDateDifference(
                        start,
                        end,
                      );
                      controller.applyTextResult(
                        display:
                            '${result.totalDays} gun | ${result.totalWeeks.toStringAsFixed(2)} hafta | '
                            '${result.wholeMonths} ay | ${result.wholeYears} yil | '
                            '${result.totalHours} saat | ${result.totalMinutes} dk',
                        historyLabel:
                            'DATE_DIFF(${start.toIso8601String()} - ${end.toIso8601String()})',
                      );
                    }

                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );

    valueController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    ohmVoltageController.dispose();
    ohmCurrentController.dispose();
    ohmResistanceController.dispose();
    powerController.dispose();
    powerVoltageController.dispose();
    powerCurrentController.dispose();
  }

  Widget _buildConvertUnitSection({
    required TextEditingController valueController,
    required List<ConvertUnit> units,
    required ConvertUnit fromUnit,
    required ConvertUnit toUnit,
    required String preview,
    required VoidCallback onChanged,
    required ValueChanged<ConvertUnit> onFromChanged,
    required ValueChanged<ConvertUnit> onToChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: valueController,
                onChanged: (_) => onChanged(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Deger',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<ConvertUnit>(
                initialValue: fromUnit,
                items: units
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onFromChanged(value);
                },
                decoration: const InputDecoration(
                  labelText: 'Baslangic birim',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sonuc',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  preview,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<ConvertUnit>(
                initialValue: toUnit,
                items: units
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onToChanged(value);
                },
                decoration: const InputDecoration(
                  labelText: 'Donusturulecek birim',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOhmLawSection({
    required TextEditingController voltageController,
    required TextEditingController currentController,
    required TextEditingController resistanceController,
    required String preview,
    required VoidCallback onTextChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Iki alan girin, bos kalan ucuncu alan otomatik hesaplanir.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: voltageController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Volt (V)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: currentController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Amper (A)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: resistanceController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Direnc (Ohm)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Sonuc',
            border: OutlineInputBorder(),
          ),
          child: Text(
            preview,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildElectricPowerSection({
    required TextEditingController powerController,
    required TextEditingController voltageController,
    required TextEditingController currentController,
    required String preview,
    required VoidCallback onTextChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Iki alan girin, bos kalan ucuncu alan otomatik hesaplanir.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: powerController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Watt (W)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: voltageController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Volt (V)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: currentController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Amper (A)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Sonuc',
            border: OutlineInputBorder(),
          ),
          child: Text(
            preview,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildDateDifferenceSection({
    required TextEditingController startDateController,
    required TextEditingController endDateController,
    required String preview,
    required VoidCallback onTextChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: startDateController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Baslangic (YYYY-MM-DD veya YYYY-MM-DD HH:MM)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: endDateController,
          onChanged: (_) => onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Bitis (YYYY-MM-DD veya YYYY-MM-DD HH:MM)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Sonuc',
            border: OutlineInputBorder(),
          ),
          child: Text(
            preview,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  List<ConvertUnit> _unitsForMode(_ConvertToolMode mode) {
    final category = switch (mode) {
      _ConvertToolMode.length => ConvertCategory.length,
      _ConvertToolMode.area => ConvertCategory.area,
      _ConvertToolMode.volume => ConvertCategory.volume,
      _ConvertToolMode.weight => ConvertCategory.weight,
      _ConvertToolMode.time => ConvertCategory.time,
      _ConvertToolMode.temperature => ConvertCategory.temperature,
      _ConvertToolMode.speed => ConvertCategory.speed,
      _ConvertToolMode.pressure => ConvertCategory.pressure,
      _ConvertToolMode.energy => ConvertCategory.energy,
      _ConvertToolMode.power => ConvertCategory.power,
      _ConvertToolMode.angle => ConvertCategory.angle,
      _ConvertToolMode.data => ConvertCategory.data,
      _ConvertToolMode.electricUnit => ConvertCategory.electricUnit,
      _ConvertToolMode.electricOhm => null,
      _ConvertToolMode.electricPower => null,
      _ConvertToolMode.dateDifference => null,
    };
    if (category == null) return const [];
    return convertUnits.where((unit) => unit.category == category).toList();
  }

  bool _isUnitMode(_ConvertToolMode mode) {
    return !{
      _ConvertToolMode.electricOhm,
      _ConvertToolMode.electricPower,
      _ConvertToolMode.dateDifference,
    }.contains(mode);
  }

  String _convertModeLabel(_ConvertToolMode mode) => switch (mode) {
    _ConvertToolMode.length => 'Uzunluk',
    _ConvertToolMode.area => 'Alan',
    _ConvertToolMode.volume => 'Hacim',
    _ConvertToolMode.weight => 'Agirlik',
    _ConvertToolMode.time => 'Zaman',
    _ConvertToolMode.temperature => 'Sicaklik',
    _ConvertToolMode.speed => 'Hiz',
    _ConvertToolMode.pressure => 'Basinc',
    _ConvertToolMode.energy => 'Enerji',
    _ConvertToolMode.power => 'Guc',
    _ConvertToolMode.angle => 'Aci',
    _ConvertToolMode.data => 'Veri',
    _ConvertToolMode.electricUnit => 'Elektrik Donusum',
    _ConvertToolMode.electricOhm => 'Elektrik Hesap (V/A/Ohm)',
    _ConvertToolMode.electricPower => 'Elektrik Hesap (W/V/A)',
    _ConvertToolMode.dateDifference => 'Iki Tarih Arasi Fark',
  };

  String _buildConversionPreview({
    required String rawValue,
    required ConvertUnit fromUnit,
    required ConvertUnit toUnit,
    required bool enabled,
  }) {
    if (!enabled) return '-';
    final value = _tryParseNumber(rawValue);
    if (value == null) return '-';
    final result = toUnit.fromBase(fromUnit.toBase(value));
    return '${_formatResultNumber(result)} ${toUnit.label}';
  }

  String _buildOhmPreview({
    required double? voltage,
    required double? current,
    required double? resistance,
  }) {
    final target = _resolveOhmTarget(
      voltage: voltage,
      current: current,
      resistance: resistance,
    );
    if (target == null) return '-';
    final result = switch (target) {
      ElectricOhmTarget.voltage when current != null && resistance != null =>
        '${_formatResultNumber(current * resistance)} V',
      ElectricOhmTarget.current
          when voltage != null && resistance != null && resistance != 0 =>
        '${_formatResultNumber(voltage / resistance)} A',
      ElectricOhmTarget.resistance
          when voltage != null && current != null && current != 0 =>
        '${_formatResultNumber(voltage / current)} Ohm',
      _ => '-',
    };
    return result;
  }

  String _buildElectricPowerPreview({
    required double? power,
    required double? voltage,
    required double? current,
  }) {
    final target = _resolvePowerTarget(
      power: power,
      voltage: voltage,
      current: current,
    );
    if (target == null) return '-';
    final result = switch (target) {
      ElectricPowerTarget.power when voltage != null && current != null =>
        '${_formatResultNumber(voltage * current)} W',
      ElectricPowerTarget.voltage
          when power != null && current != null && current != 0 =>
        '${_formatResultNumber(power / current)} V',
      ElectricPowerTarget.current
          when power != null && voltage != null && voltage != 0 =>
        '${_formatResultNumber(power / voltage)} A',
      _ => '-',
    };
    return result;
  }

  ElectricOhmTarget? _resolveOhmTarget({
    required double? voltage,
    required double? current,
    required double? resistance,
  }) {
    if (voltage == null && current != null && resistance != null) {
      return ElectricOhmTarget.voltage;
    }
    if (current == null && voltage != null && resistance != null) {
      return ElectricOhmTarget.current;
    }
    if (resistance == null && voltage != null && current != null) {
      return ElectricOhmTarget.resistance;
    }
    return null;
  }

  ElectricPowerTarget? _resolvePowerTarget({
    required double? power,
    required double? voltage,
    required double? current,
  }) {
    if (power == null && voltage != null && current != null) {
      return ElectricPowerTarget.power;
    }
    if (voltage == null && power != null && current != null) {
      return ElectricPowerTarget.voltage;
    }
    if (current == null && power != null && voltage != null) {
      return ElectricPowerTarget.current;
    }
    return null;
  }

  String _buildDatePreview({required DateTime? start, required DateTime? end}) {
    if (start == null || end == null) return '-';
    final orderedStart = start.isBefore(end) ? start : end;
    final orderedEnd = start.isBefore(end) ? end : start;
    final duration = orderedEnd.difference(orderedStart);
    var months =
        ((orderedEnd.year - orderedStart.year) * 12) +
        (orderedEnd.month - orderedStart.month);
    if (orderedEnd.day < orderedStart.day) {
      months -= 1;
    }
    final years = months ~/ 12;
    return '${duration.inDays} gun | ${(duration.inHours / (24 * 7)).toStringAsFixed(2)} hafta | $months ay | $years yil | ${duration.inHours} saat | ${duration.inMinutes} dk';
  }

  String _formatResultNumber(double value) {
    if (!value.isFinite) return 'Hata';
    final rounded = value.toStringAsFixed(6);
    return rounded
        .replaceFirst(RegExp(r'\.?0+$'), '')
        .replaceAll(',', '.');
  }

  double? _tryParseNumber(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _SquareMode { circle, rectangle, latLon }

class _StandardKeySpec {
  const _StandardKeySpec({
    required this.label,
    required this.row,
    required this.col,
    this.colSpan = 1,
  });

  final String label;
  final int row;
  final int col;
  final int colSpan;
}
