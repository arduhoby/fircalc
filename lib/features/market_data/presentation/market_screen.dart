import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/flavor/app_flavor.dart';
import '../application/market_quote_provider.dart';
import '../domain/market_models.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(trackedFxRatesProvider);
    final watchAsync = ref.watch(trackedMarketWatchProvider);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: const Text('TCMB Takip Seti'),
                subtitle: Text(
                  AppFlavor.enableLiveMarketProviders
                      ? 'USD/EUR/GBP + BTC, ETH, Gram Altın, Çeyrek Altın, Brent izleniyor.'
                      : 'Lite modda canlı provider kapalı. Son kayıtlı/manüel veri gösteriliyor.',
                ),
                trailing: IconButton(
                  onPressed: () => ref.invalidate(trackedFxRatesProvider),
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: quoteAsync.when(
                          data: (rows) =>
                              _RatesTable(rows: rows, locale: locale),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => const Center(
                            child: Text(
                              'Kur verisi alınamadı. Fallback verisi kullanılmalı.',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: watchAsync.when(
                          data: (rows) =>
                              _MarketWatchTable(rows: rows, locale: locale),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => const Center(
                            child: Text('Piyasa verisi alınamadı.'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketWatchTable extends StatelessWidget {
  const _MarketWatchTable({required this.rows, required this.locale});

  final List<MarketWatchSnapshot> rows;
  final String locale;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text('Gösterilecek piyasa verisi bulunamadı.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Piyasa İzleme',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Kod')),
                  DataColumn(label: Text('Ad')),
                  DataColumn(label: Text('Fiyat')),
                  DataColumn(label: Text('Birim')),
                  DataColumn(label: Text('Kaynak')),
                ],
                rows: rows
                    .map(
                      (e) => DataRow(
                        cells: [
                          DataCell(Text(e.code)),
                          DataCell(Text(e.name)),
                          DataCell(
                            Text(
                              _RatesTable._fmt(e.priceTry.toString(), locale),
                            ),
                          ),
                          DataCell(Text(e.unit)),
                          DataCell(
                            Text(_RatesTable._sourceText(e.source, e.status)),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RatesTable extends StatelessWidget {
  const _RatesTable({required this.rows, required this.locale});

  final List<FxRateSnapshot> rows;
  final String locale;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('Gösterilecek kur verisi bulunamadı.'));
    }

    final sorted = [...rows]
      ..sort((a, b) {
        final c = a.currency.code.compareTo(b.currency.code);
        if (c != 0) return c;
        return a.kind.index.compareTo(b.kind.index);
      });

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Kur')),
                DataColumn(label: Text('Alış')),
                DataColumn(label: Text('Satış')),
                DataColumn(label: Text('Kaynak')),
                DataColumn(label: Text('Tip')),
              ],
              rows: sorted
                  .map(
                    (e) => DataRow(
                      cells: [
                        DataCell(
                          _CurrencyCell(
                            code: e.currency.code,
                            symbol: _currencySymbol(e.currency.code),
                            flag: _flagEmoji(e.currency.code),
                          ),
                        ),
                        DataCell(Text(_fmt(e.buy.toString(), locale))),
                        DataCell(Text(_fmt(e.sell.toString(), locale))),
                        DataCell(Text(_sourceText(e.source, e.status))),
                        DataCell(
                          Text(
                            e.kind == FxRateKind.daily ? 'Günlük' : 'Efektif',
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  static String _fmt(String raw, String locale) {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null) return raw;
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 4,
    ).format(value);
  }

  static String _sourceText(DataSourceType source, MarketDataStatus status) {
    if (status == MarketDataStatus.stale) return 'Cache (stale)';
    return switch (source) {
      DataSourceType.tcmbDaily => 'TCMB',
      DataSourceType.tcmbHourly => 'TCMB',
      DataSourceType.apiFallback => 'Fallback API',
      DataSourceType.scraping => 'Scraping',
      DataSourceType.cache => 'Cache',
      DataSourceType.manual => 'Manual',
    };
  }

  static String _currencySymbol(String code) {
    return switch (code) {
      'USD' => r'$',
      'EUR' => 'E',
      'GBP' => '&',
      _ => '',
    };
  }

  static String _flagEmoji(String code) {
    return switch (code) {
      'USD' => '🇺🇸',
      'EUR' => '🇪🇺',
      'GBP' => '🇬🇧',
      _ => '🏳️',
    };
  }
}

class _CurrencyCell extends StatelessWidget {
  const _CurrencyCell({
    required this.code,
    required this.symbol,
    required this.flag,
  });

  final String code;
  final String symbol;
  final String flag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRY/$code'),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(symbol, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(flag, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
