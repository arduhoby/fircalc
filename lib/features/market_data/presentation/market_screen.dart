import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/types/decimal_value.dart';
import '../application/market_news_provider.dart';
import '../application/market_quote_provider.dart';
import '../domain/market_models.dart';
import '../domain/market_news_item.dart';
import '../../settings/application/display_settings_controller.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(trackedFxRatesProvider);
    final watchAsync = ref.watch(trackedMarketWatchProvider);
    final settings = ref.watch(displaySettingsProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: quoteAsync.when(
              data: (fxRows) => watchAsync.when(
                data: (watchRows) => _UnifiedMarketTable(
                  fxRows: fxRows,
                  watchRows: watchRows,
                  locale: locale,
                  marketDigits: settings.marketPriceDigits,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    const Center(child: Text('Piyasa verisi alınamadı.')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  const Center(child: Text('Kur verisi alınamadı.')),
            ),
          ),
        ),
      ),
    );
  }
}

class MarketNewsScreen extends ConsumerWidget {
  const MarketNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(marketNewsProvider);
    final settings = ref.watch(displaySettingsProvider);
    final controller = ref.read(displaySettingsProvider.notifier);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final selectedSource = settings.marketNewsSelectedSource.trim();
    final sources = settings.marketNewsSources.toSet().toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NewsSourcePicker(
                  sources: sources,
                  selectedSource: selectedSource,
                  onChanged: (value) {
                    unawaited(
                      controller.setMarketNewsSelectedSource(value ?? ''),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: newsAsync.when(
                    data: (rows) =>
                        _MarketNewsList(rows: rows, locale: locale),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) =>
                        const Center(child: Text('Haberler alınamadı.')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnifiedMarketTable extends StatelessWidget {
  const _UnifiedMarketTable({
    required this.fxRows,
    required this.watchRows,
    required this.locale,
    required this.marketDigits,
  });

  final List<FxRateSnapshot> fxRows;
  final List<MarketWatchSnapshot> watchRows;
  final String locale;
  final int marketDigits;

  @override
  Widget build(BuildContext context) {
    final rows = <_MarketRow>[
      ...fxRows.map((item) => _MarketRow.fromFx(item, marketDigits)),
      ...watchRows.map((item) => _MarketRow.fromWatch(item, marketDigits)),
    ]..sort((a, b) => a.sortKey.compareTo(b.sortKey));

    if (rows.isEmpty) {
      return const Center(child: Text('Gösterilecek veri bulunamadı.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Piyasa Verileri',
          updatedAt: _latestTimestamp(rows.map((item) => item.timestamp)),
          locale: locale,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 12,
                    horizontalMargin: 8,
                    dataRowMinHeight: 34,
                    dataRowMaxHeight: 40,
                    headingRowHeight: 38,
                    columns: const [
                      DataColumn(label: Text('Kod')),
                      DataColumn(label: Text('Alış')),
                      DataColumn(label: Text('Satış / Fiyat')),
                      DataColumn(label: Text('Ad')),
                      DataColumn(label: Text('Tip')),
                      DataColumn(label: Text('Birim')),
                    ],
                    rows: rows
                        .map(
                          (row) => DataRow(
                            cells: [
                              DataCell(Text(row.code)),
                              DataCell(Text(row.buyText ?? '-')),
                              DataCell(
                                Text(
                                  row.sellOrPriceText,
                                  style: TextStyle(color: row.priceColor),
                                ),
                                onTap: row.snapshot == null
                                    ? null
                                    : () => _showMarketDetail(context, row),
                              ),
                              DataCell(Text(row.name)),
                              DataCell(Text(row.typeLabel)),
                              DataCell(Text(row.unit)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showMarketDetail(BuildContext context, _MarketRow row) {
    final snapshot = row.snapshot;
    if (snapshot == null) return Future.value();
    final detailRows = <MapEntry<String, String>>[
      MapEntry('Kod', row.code),
      MapEntry('Ad', row.name),
      MapEntry('Acilis', row.buyText ?? '-'),
      MapEntry('Kapanis', row.closeText ?? row.sellOrPriceText),
      MapEntry(
        'Anlik',
        _MarketRow.formatDecimal(
          snapshot.priceTry,
          marketDigits,
          snapshot.unit,
        ),
      ),
      MapEntry(
        'Gun Ici En Dusuk',
        snapshot.lowTry == null
            ? '-'
            : _MarketRow.formatDecimal(
                snapshot.lowTry!,
                marketDigits,
                snapshot.unit,
              ),
      ),
      MapEntry(
        'Gun Ici En Yuksek',
        snapshot.highTry == null
            ? '-'
            : _MarketRow.formatDecimal(
                snapshot.highTry!,
                marketDigits,
                snapshot.unit,
              ),
      ),
    ];
    return showDialog<void>(
      context: context,
      builder: (context) {
        var startDate = DateTime.now().subtract(const Duration(days: 30));
        return StatefulBuilder(
          builder: (context, setState) {
            final historyFuture = fetchStockHistory(
              row.code,
              startDate: startDate,
            );
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SizedBox(
                width: 760,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: FutureBuilder<List<MarketHistoryPoint>>(
                    future: historyFuture,
                    builder: (context, historySnapshot) {
                      final points =
                          historySnapshot.data ?? const <MarketHistoryPoint>[];
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.code,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        row.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Kapat'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final selected = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2010),
                                      lastDate: DateTime.now(),
                                      initialDate: startDate,
                                    );
                                    if (selected != null) {
                                      setState(() => startDate = selected);
                                    }
                                  },
                                  icon: const Icon(Icons.event_outlined),
                                  label: Text(
                                    'Baslangic: ${DateFormat('dd.MM.yyyy').format(startDate)}',
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    'Bugun: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                border: Border.all(
                                  color: const Color(0xFFD9E2EC),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Fiyat Grafigi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    points.isEmpty
                                        ? 'Secilen aralikta grafik verisi bulunamadi.'
                                        : '${DateFormat('dd.MM.yyyy').format(points.first.time)} - ${DateFormat('dd.MM.yyyy').format(points.last.time)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 280,
                                    child: points.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Secilen aralikta veri yok.',
                                            ),
                                          )
                                        : _HistoryLineChart(
                                            points: points,
                                            digits: marketDigits,
                                            unit: row.unit,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: detailRows
                                  .map(
                                    (entry) => _MetricCard(
                                      title: entry.key,
                                      value: entry.value,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MarketNewsList extends StatelessWidget {
  const _MarketNewsList({required this.rows, required this.locale});

  final List<MarketNewsItem> rows;
  final String locale;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('Gösterilecek haber bulunamadı.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Piyasa Haberleri',
          updatedAt: _latestTimestamp(
            rows.map((item) => item.publishedAt).whereType<DateTime>(),
          ),
          locale: locale,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final item = rows[index];
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openNews(context, item.url),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _newsMeta(item),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _newsMeta(MarketNewsItem item) {
    final publishedAt = item.publishedAt;
    if (publishedAt == null) return item.sourceLabel;
    return '${item.sourceLabel} • ${DateFormat('dd.MM.yyyy HH:mm', locale).format(publishedAt)}';
  }

  Future<void> _openNews(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Haber baglantisi acilamadi.')),
    );
  }
}

class _NewsSourcePicker extends StatelessWidget {
  const _NewsSourcePicker({
    required this.sources,
    required this.selectedSource,
    required this.onChanged,
  });

  final List<String> sources;
  final String selectedSource;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('Tümü'),
      ),
      ...sources.map(
        (source) => DropdownMenuItem<String>(
          value: source,
          child: Text(_labelFor(source)),
        ),
      ),
    ];

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Haber kaynağı',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sources.contains(selectedSource) ? selectedSource : '',
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _labelFor(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null) return source;
    if (uri.host.contains('bigpara.hurriyet.com.tr')) {
      return 'Bigpara RSS';
    }
    final host = uri.host.replaceFirst('www.', '');
    final path = uri.pathSegments.isEmpty
        ? ''
        : '/${uri.pathSegments.last}';
    return '$host$path';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.updatedAt,
    required this.locale,
  });

  final String title;
  final DateTime? updatedAt;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final timestamp = updatedAt;
    final subtitle = timestamp == null
        ? 'Tarih bilgisi yok'
        : 'Veri zamanı: ${DateFormat('dd.MM.yyyy HH:mm', locale).format(timestamp)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _HistoryLineChart extends StatelessWidget {
  const _HistoryLineChart({
    required this.points,
    required this.digits,
    required this.unit,
  });

  final List<MarketHistoryPoint> points;
  final int digits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final numericValues = points
        .map((point) => double.tryParse(point.value.toString()) ?? 0)
        .toList();
    final minValue = numericValues.reduce((a, b) => a < b ? a : b);
    final maxValue = numericValues.reduce((a, b) => a > b ? a : b);
    final middleValue = (minValue + maxValue) / 2;
    final axisValues = [maxValue, middleValue, minValue];

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 84,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: axisValues
                        .map(
                          (value) => Text(
                            _MarketRow.formatDecimal(
                              DecimalValue.parse(value.toString()),
                              digits,
                              unit,
                            ),
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Expanded(
                child: CustomPaint(
                  painter: _HistoryLineChartPainter(points: points),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd.MM.yyyy').format(points.first.time),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            Text(
              DateFormat('dd.MM.yyyy').format(points.last.time),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryLineChartPainter extends CustomPainter {
  const _HistoryLineChartPainter({required this.points});

  final List<MarketHistoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = points
        .map((point) => double.tryParse(point.value.toString()) ?? 0)
        .toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.000001
        ? 1.0
        : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (var i = 1; i <= 3; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 1; i <= 3; i++) {
      final x = (size.width / 4) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? 0.0
          : (size.width / (values.length - 1)) * i;
      final normalized = (values[i] - minValue) / range;
      final y = size.height - (normalized * (size.height - 20)) - 10;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = const Color(0xFF2563EB),
      );
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _HistoryLineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketRow {
  const _MarketRow({
    required this.sortKey,
    required this.code,
    required this.name,
    required this.typeLabel,
    required this.buyText,
    required this.sellOrPriceText,
    required this.closeText,
    required this.unit,
    required this.timestamp,
    required this.priceColor,
    this.snapshot,
  });

  factory _MarketRow.fromFx(FxRateSnapshot item, int digits) {
    return _MarketRow(
      sortKey: '0-${item.currency.code}-${item.kind.name}',
      code: item.currency.code,
      name: 'TRY/${item.currency.code}',
      typeLabel: item.kind == FxRateKind.daily ? 'Kur Günlük' : 'Kur Efektif',
      buyText: formatRaw(item.buy.toString(), digits),
      sellOrPriceText: formatRaw(item.sell.toString(), digits),
      closeText: null,
      unit: 'TRY',
      timestamp: item.timestamp,
      priceColor: null,
    );
  }

  factory _MarketRow.fromWatch(MarketWatchSnapshot item, int digits) {
    return _MarketRow(
      sortKey: '${_order(item)}-${item.code}',
      code: item.code,
      name: item.name,
      typeLabel: switch (item.kind) {
        MarketWatchKind.crypto => 'Kripto',
        MarketWatchKind.preciousMetal => 'Emtia',
        MarketWatchKind.stock => 'Hisse',
        MarketWatchKind.energy => 'Enerji',
      },
      buyText: item.openTry == null
          ? null
          : formatDecimal(item.openTry!, digits, item.unit),
      sellOrPriceText: item.closeTry == null
          ? formatDecimal(item.priceTry, digits, item.unit)
          : formatDecimal(item.closeTry!, digits, item.unit),
      closeText: item.closeTry == null
          ? null
          : formatDecimal(item.closeTry!, digits, item.unit),
      unit: item.unit,
      timestamp: item.timestamp,
      priceColor: _trendColor(item),
      snapshot: item,
    );
  }

  final String sortKey;
  final String code;
  final String name;
  final String typeLabel;
  final String? buyText;
  final String sellOrPriceText;
  final String? closeText;
  final String unit;
  final DateTime timestamp;
  final Color? priceColor;
  final MarketWatchSnapshot? snapshot;

  static String formatRaw(String raw, int digits) {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return raw;
    return NumberFormat.decimalPatternDigits(
      locale: 'tr-TR',
      decimalDigits: digits,
    ).format(value);
  }

  static String formatDecimal(dynamic value, int digits, String unit) {
    final formatted = formatRaw(value.toString(), digits);
    return unit == 'USD' ? '$formatted\$' : formatted;
  }

  static String _order(MarketWatchSnapshot item) {
    if (item.code == 'XAU_GR') return '1';
    if (item.kind == MarketWatchKind.stock) return '2';
    if (item.code == 'CEYREK') return '3';
    if (item.kind == MarketWatchKind.crypto) return '4';
    return '5';
  }

  static Color? _trendColor(MarketWatchSnapshot item) {
    if (item.kind != MarketWatchKind.stock) return null;
    final reference = item.closeTry ?? item.openTry;
    if (reference == null) return null;
    final current = double.tryParse(item.priceTry.toString());
    final ref = double.tryParse(reference.toString());
    if (current == null || ref == null) return null;
    if (current > ref) {
      return const Color(0xFF1B8F3A);
    }
    if (current < ref) {
      return const Color(0xFFC62828);
    }
    return const Color(0xFF455A64);
  }
}

DateTime? _latestTimestamp(Iterable<DateTime> items) {
  DateTime? latest;
  for (final item in items) {
    if (latest == null || item.isAfter(latest)) {
      latest = item;
    }
  }
  return latest;
}
