import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/number_display_formatter.dart';
import '../../../core/widgets/calc_key_button.dart';
import '../../../core/types/decimal_value.dart';
import '../../market_data/application/market_quote_provider.dart';
import '../../market_data/domain/market_models.dart';
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
    final fxRates = ref
        .watch(trackedFxRatesProvider)
        .maybeWhen(
          data: (list) => _EffectiveFxRates.fromSnapshots(list),
          orElse: _EffectiveFxRates.empty,
        );
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
            const SizedBox(height: 8),
            _TapeDisplay(state: state, locale: locale, settings: settings),
            const SizedBox(height: 8),
            _TapeKeypad(
              controller: controller,
              settings: settings,
              fxRates: fxRates,
            ),
          ],
        ),
      ),
    );
  }
}

class _TapePaper extends StatefulWidget {
  const _TapePaper({
    required this.state,
    required this.locale,
    required this.settings,
  });

  final TapeSessionState state;
  final String locale;
  final DisplaySettings settings;

  @override
  State<_TapePaper> createState() => _TapePaperState();
}

class _TapePaperState extends State<_TapePaper> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(covariant _TapePaper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.lines.length != widget.state.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: widget.state.lines.length,
          itemBuilder: (context, index) {
            final line = widget.state.lines[index];
            final rowHeight =
                line.kind == TapeLineKind.normal && line.expression != null
                ? 52.0
                : 38.0;
            return SizedBox(
              height: rowHeight,
              child: _TapeLineRow(
                line: line,
                locale: widget.locale,
                settings: widget.settings,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TapeDisplay extends StatelessWidget {
  const _TapeDisplay({
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

    const panelColor = Color(0xFF253322);
    const segmentColor = Color(0xFFB8FF4A);

    return Container(
      width: double.infinity,
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4A5A45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _SevenSegmentText(
            text: display,
            color: segmentColor,
            charWidth: 19,
            charHeight: 34,
            gap: 2,
          ),
        ),
      ),
    );
  }
}

class _SevenSegmentText extends StatelessWidget {
  const _SevenSegmentText({
    required this.text,
    required this.color,
    required this.charWidth,
    required this.charHeight,
    required this.gap,
  });

  final String text;
  final Color color;
  final double charWidth;
  final double charHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) {
        return Padding(
          padding: EdgeInsets.only(left: gap),
          child: SizedBox(
            width: _charWidthFor(char),
            height: charHeight,
            child: CustomPaint(
              painter: _SevenSegmentPainter(char: char, color: color),
            ),
          ),
        );
      }).toList(),
    );
  }

  double _charWidthFor(String c) {
    if (c == ',' || c == '.') return charWidth * 0.45;
    if (c == ' ') return charWidth * 0.35;
    return charWidth;
  }
}

class _SevenSegmentPainter extends CustomPainter {
  const _SevenSegmentPainter({required this.char, required this.color});

  final String char;
  final Color color;

  static const _map = <String, Set<String>>{
    '0': {'a', 'b', 'c', 'd', 'e', 'f'},
    '1': {'b', 'c'},
    '2': {'a', 'b', 'g', 'e', 'd'},
    '3': {'a', 'b', 'g', 'c', 'd'},
    '4': {'f', 'g', 'b', 'c'},
    '5': {'a', 'f', 'g', 'c', 'd'},
    '6': {'a', 'f', 'g', 'c', 'd', 'e'},
    '7': {'a', 'b', 'c'},
    '8': {'a', 'b', 'c', 'd', 'e', 'f', 'g'},
    '9': {'a', 'b', 'c', 'd', 'f', 'g'},
    '-': {'g'},
  };

  @override
  void paint(Canvas canvas, Size size) {
    final active = Paint()..color = color;
    final passive = Paint()..color = color.withValues(alpha: 0.12);
    final t = math.max(2.0, size.width * 0.15);

    if (char == '.' || char == ',') {
      final r = Rect.fromLTWH(size.width - t, size.height - t * 1.4, t, t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(t * 0.35)),
        active,
      );
      return;
    }

    final activeSet = _map[char] ?? const <String>{};

    Rect h(double y) => Rect.fromLTWH(t, y, size.width - 2 * t, t);
    Rect v(double x, double y1, double y2) => Rect.fromLTWH(x, y1, t, y2 - y1);

    final seg = <String, Rect>{
      'a': h(0),
      'g': h((size.height - t) / 2),
      'd': h(size.height - t),
      'f': v(0, t, (size.height - t) / 2),
      'b': v(size.width - t, t, (size.height - t) / 2),
      'e': v(0, (size.height + t) / 2, size.height - t),
      'c': v(size.width - t, (size.height + t) / 2, size.height - t),
    };

    for (final entry in seg.entries) {
      final paint = activeSet.contains(entry.key) ? active : passive;
      canvas.drawRRect(
        RRect.fromRectAndRadius(entry.value, Radius.circular(t * 0.35)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SevenSegmentPainter oldDelegate) {
    return oldDelegate.char != char || oldDelegate.color != color;
  }
}

class _TapeLineRow extends StatelessWidget {
  const _TapeLineRow({
    required this.line,
    required this.locale,
    required this.settings,
  });

  final TapeLine line;
  final String locale;
  final DisplaySettings settings;

  @override
  Widget build(BuildContext context) {
    final tapeLine = line;
    final isSubtotal = tapeLine.kind == TapeLineKind.subtotal;
    final isGrandTotal = tapeLine.kind == TapeLineKind.grandTotal;

    final metaLabel = switch (tapeLine.kind) {
      TapeLineKind.subtotal => 'Ara Toplam',
      TapeLineKind.grandTotal => 'Genel Toplam',
      _ => tapeLine.expression ?? '',
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
            width: 150,
            child: Text(
              metaLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
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

class _TapeKeypad extends StatelessWidget {
  const _TapeKeypad({
    required this.controller,
    required this.settings,
    required this.fxRates,
  });

  final TapeController controller;
  final DisplaySettings settings;
  final _EffectiveFxRates fxRates;

  @override
  Widget build(BuildContext context) {
    final leftAuxLabel = settings.tapeAuxLeft.label;
    final rightAuxLabel = settings.tapeAuxRight.label;

    final specs = [
      const _KeySpec(
        label: 'C',
        row: 0,
        col: 0,
        backgroundColor: Color(0xFFB00020),
      ),
      const _KeySpec(label: 'M+', row: 0, col: 1),
      const _KeySpec(label: 'M-', row: 0, col: 2),
      const _KeySpec(label: 'MR', row: 0, col: 3),
      const _KeySpec(label: 'MC', row: 0, col: 4),
      const _KeySpec(label: '%', row: 1, col: 0),
      const _KeySpec(label: 'VAT', row: 1, col: 1),
      _KeySpec(label: leftAuxLabel, row: 1, col: 2),
      _KeySpec(label: rightAuxLabel, row: 1, col: 3),
      const _KeySpec(label: '<', row: 1, col: 4),
      const _KeySpec(label: '7', row: 2, col: 0),
      const _KeySpec(label: '8', row: 2, col: 1),
      const _KeySpec(label: '9', row: 2, col: 2),
      const _KeySpec(label: '÷', row: 2, col: 3),
      const _KeySpec(label: 'CE', row: 2, col: 4),
      const _KeySpec(label: '4', row: 3, col: 0),
      const _KeySpec(label: '5', row: 3, col: 1),
      const _KeySpec(label: '6', row: 3, col: 2),
      const _KeySpec(label: '×', row: 3, col: 3),
      const _KeySpec(label: '1', row: 4, col: 0),
      const _KeySpec(label: '2', row: 4, col: 1),
      const _KeySpec(label: '3', row: 4, col: 2),
      const _KeySpec(label: '-', row: 4, col: 3),
      const _KeySpec(label: '+', row: 3, col: 4, rowSpan: 2),
      const _KeySpec(label: '0', row: 5, col: 0),
      const _KeySpec(label: '000', row: 5, col: 1),
      const _KeySpec(label: ',', row: 5, col: 2),
      const _KeySpec(label: '=', row: 5, col: 3, colSpan: 2),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 5;
        const rows = 6;
        _validateSpecs(specs, rows: rows, cols: cols);
        const gap = 8.0;
        final keyHeight = settings.tapeKeyHeight.toDouble();
        final keyWidth = (constraints.maxWidth - ((cols - 1) * gap)) / cols;
        final totalHeight = (rows * keyHeight) + ((rows - 1) * gap);

        return SizedBox(
          height: totalHeight,
          child: Stack(
            children: specs.map((spec) {
              final left = spec.col * (keyWidth + gap);
              final top = spec.row * (keyHeight + gap);
              final width =
                  (spec.colSpan * keyWidth) + ((spec.colSpan - 1) * gap);
              final height =
                  (spec.rowSpan * keyHeight) + ((spec.rowSpan - 1) * gap);
              final isOperator = [
                '÷',
                '×',
                '-',
                '+',
                '%',
                'VAT',
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
                  backgroundColor: spec.backgroundColor,
                  foregroundColor: spec.backgroundColor == null
                      ? null
                      : Colors.white,
                  onTap: () {
                    unawaited(_tap(context, spec.label));
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _playSound() {
    if (settings.tapeKeySoundEnabled) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _tap(BuildContext context, String key) async {
    _playSound();

    if (key == settings.tapeAuxLeft.label ||
        key == settings.tapeAuxRight.label) {
      await _handleAuxCurrency(context, key);
      return;
    }

    switch (key) {
      case 'C':
        controller.clearAll();
        return;
      case 'CE':
        controller.clearEntry();
        return;
      case '<':
        controller.backspace();
        return;
      case 'MR':
        controller.memoryRecall(TapeMemorySlot.m1);
        return;
      case 'M+':
        controller.memoryAdd(TapeMemorySlot.m1);
        return;
      case 'M-':
        controller.memorySubtract(TapeMemorySlot.m1);
        return;
      case 'MC':
        controller.memoryClear(TapeMemorySlot.m1);
        return;
      case '%':
        controller.percent();
        return;
      case 'VAT':
        final mode = await _askVatMode(context);
        if (mode == null) return;
        controller.vat(
          ratePercent: settings.vatRatePercent.toString(),
          mode: mode,
        );
        return;
      case '÷':
        controller.startDivide();
        return;
      case '×':
        controller.startMultiply();
        return;
      case '-':
        controller.addMinus();
        return;
      case '+':
        controller.addPlus();
        return;
      case '=':
        controller.equals();
        return;
      case ',':
        controller.decimalPoint();
        return;
      default:
        controller.digit(key);
        return;
    }
  }

  Future<void> _handleAuxCurrency(BuildContext context, String key) async {
    final currency = switch (key) {
      r'$' => 'USD',
      'E' => 'EUR',
      '&' => 'GBP',
      _ => null,
    };
    if (currency == null) return;

    final rate = switch (currency) {
      'USD' => fxRates.usd,
      'EUR' => fxRates.eur,
      'GBP' => fxRates.gbp,
      _ => null,
    };

    if (rate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$currency efektif satış verisi bulunamadı')),
      );
      return;
    }

    controller.applyEffectiveFxRate(
      currencyLabel: currency,
      rate: rate.toString(),
    );
  }

  Future<TapeVatMode?> _askVatMode(BuildContext context) {
    return showCupertinoModalPopup<TapeVatMode>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('KDV %${settings.vatRatePercent}'),
        message: const Text('Girilen tutar KDV dahil mi, hariç mi?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, TapeVatMode.included),
            child: const Text('Dahil'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, TapeVatMode.excluded),
            child: const Text('Hariç'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
      ),
    );
  }

  void _validateSpecs(
    List<_KeySpec> specs, {
    required int rows,
    required int cols,
  }) {
    final occupied = <String>{};
    for (final spec in specs) {
      for (var r = spec.row; r < spec.row + spec.rowSpan; r++) {
        for (var c = spec.col; c < spec.col + spec.colSpan; c++) {
          if (r < 0 || c < 0 || r >= rows || c >= cols) {
            throw FlutterError(
              'Key "${spec.label}" grid disinda: row=$r col=$c (rows=$rows cols=$cols)',
            );
          }
          final key = '$r:$c';
          if (!occupied.add(key)) {
            throw FlutterError(
              'Key grid cakismasi: "${spec.label}" hucreyi tekrar kullaniyor ($key)',
            );
          }
        }
      }
    }
  }
}

class _KeySpec {
  const _KeySpec({
    required this.label,
    required this.row,
    required this.col,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.backgroundColor,
  });

  final String label;
  final int row;
  final int col;
  final int rowSpan;
  final int colSpan;
  final Color? backgroundColor;
}

class _EffectiveFxRates {
  const _EffectiveFxRates({
    required this.usd,
    required this.eur,
    required this.gbp,
  });

  final DecimalValue? usd;
  final DecimalValue? eur;
  final DecimalValue? gbp;

  factory _EffectiveFxRates.empty() => _EffectiveFxRates(
    usd: DecimalValue.parse('38.3400'),
    eur: DecimalValue.parse('41.2400'),
    gbp: DecimalValue.parse('48.2700'),
  );

  factory _EffectiveFxRates.fromSnapshots(List<FxRateSnapshot> snapshots) {
    DecimalValue? pick(String code) {
      for (final s in snapshots) {
        if (s.kind != FxRateKind.effective) continue;
        if (s.currency.code == code) return s.sell;
      }
      return null;
    }

    return _EffectiveFxRates(
      usd: pick('USD'),
      eur: pick('EUR'),
      gbp: pick('GBP'),
    );
  }
}
