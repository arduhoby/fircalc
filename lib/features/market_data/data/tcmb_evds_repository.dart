import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/types/currency_code.dart';
import '../../../core/types/decimal_value.dart';
import '../domain/market_data_repository.dart';
import '../domain/market_models.dart';

class TcmbEvdsRepository implements MarketDataRepository {
  TcmbEvdsRepository({
    required this.apiKey,
    http.Client? client,
    DateTime Function()? now,
    List<String>? baseUrls,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now,
       _baseUrls =
           baseUrls ??
           const [
             'https://evds3.tcmb.gov.tr/igmevdsms-dis/',
             'https://evds3.tcmb.gov.tr/service/evds/',
             'https://evds2.tcmb.gov.tr/service/evds/',
           ];

  final String apiKey;
  final http.Client _client;
  final DateTime Function() _now;
  final List<String> _baseUrls;

  Future<List<FxRateSnapshot>> getTrackedFxRates() async {
    final codes = ['USD', 'EUR', 'GBP'];
    final result = <FxRateSnapshot>[];
    for (final code in codes) {
      final daily = await _fetchByCandidates(
        quoteCode: code,
        kind: FxRateKind.daily,
        buySeriesCandidates: ['TP.DK.$code.A', 'TP.DK.$code.A.YTL'],
        sellSeriesCandidates: ['TP.DK.$code.S', 'TP.DK.$code.S.YTL'],
      );
      if (daily != null) result.add(daily);

      final effective = await _fetchByCandidates(
        quoteCode: code,
        kind: FxRateKind.effective,
        buySeriesCandidates: ['TP.DK.$code.EF.A', 'TP.DK.$code.EF.A.YTL'],
        sellSeriesCandidates: ['TP.DK.$code.EF.S', 'TP.DK.$code.EF.S.YTL'],
      );
      if (effective != null) result.add(effective);
    }
    return result;
  }

  @override
  Future<ExchangeRateQuote?> getExchangeRate({
    required String base,
    required String quote,
    bool forceRefresh = false,
  }) async {
    if (apiKey.trim().isEmpty) return null;
    if (base.toUpperCase() != 'TRY') return null;

    final quoteCode = quote.toUpperCase();
    final series = 'TP.DK.$quoteCode.A-TP.DK.$quoteCode.S';

    for (final baseUrl in _baseUrls) {
      final result = await _tryFetch(
        baseUrl: baseUrl,
        series: series,
        quoteCode: quoteCode,
      );
      if (result != null) return result;
    }

    return null;
  }

  Future<ExchangeRateQuote?> _tryFetch({
    required String baseUrl,
    required String series,
    required String quoteCode,
  }) async {
    final now = _now();
    final endDate = _formatDate(now);
    final startDate = _formatDate(now.subtract(const Duration(days: 7)));

    final candidates = <Uri>[
      Uri.parse(
        '${baseUrl}series=$series&startDate=$startDate&endDate=$endDate&type=json',
      ),
      Uri.parse(baseUrl).replace(
        queryParameters: {
          'series': series,
          'startDate': startDate,
          'endDate': endDate,
          'type': 'json',
        },
      ),
    ];

    for (final uri in candidates) {
      try {
        final response = await _client.get(
          uri,
          headers: {'Accept': 'application/json', 'key': apiKey},
        );
        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) continue;

        final items = data['items'];
        if (items is! List || items.isEmpty) continue;

        final last = items.last;
        if (last is! Map) continue;

        final map = <String, dynamic>{};
        for (final entry in last.entries) {
          map[entry.key.toString()] = entry.value;
        }

        final buy = _extractRate(map, quoteCode, isBuy: true);
        final sell = _extractRate(map, quoteCode, isBuy: false) ?? buy;
        if (buy == null) continue;
        final buyRate = buy;
        final sellRate = sell ?? buyRate;

        final quoteCurrency = _toCurrencyCode(quoteCode);
        if (quoteCurrency == null) return null;

        return ExchangeRateQuote(
          base: CurrencyCode.tryCode,
          quote: quoteCurrency,
          buy: buyRate,
          sell: sellRate,
          timestamp: now,
          source: DataSourceType.tcmbDaily,
          status: MarketDataStatus.live,
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  DecimalValue? _extractRate(
    Map<String, dynamic> row,
    String quoteCode, {
    required bool isBuy,
  }) {
    final suffix = isBuy ? '_A' : '_S';

    String normalize(String key) => key
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final exactNeedle = 'TP_DK_${quoteCode}_$suffix';

    for (final entry in row.entries) {
      final normalized = normalize(entry.key);
      if (!normalized.contains('TP_DK_${quoteCode}_')) continue;
      if (!normalized.contains(suffix)) continue;

      final parsed = _parseDecimal(entry.value);
      if (parsed != null) return parsed;
    }

    for (final entry in row.entries) {
      final normalized = normalize(entry.key);
      if (!normalized.contains(exactNeedle)) continue;
      final parsed = _parseDecimal(entry.value);
      if (parsed != null) return parsed;
    }

    return null;
  }

  DecimalValue? _parseDecimal(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final normalized = text.replaceAll(',', '.');
    try {
      return DecimalValue.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  CurrencyCode? _toCurrencyCode(String code) {
    return switch (code) {
      'USD' => CurrencyCode.usd,
      'EUR' => CurrencyCode.eur,
      'GBP' => CurrencyCode.gbp,
      'JPY' => CurrencyCode.jpy,
      'CNY' => CurrencyCode.cny,
      'RUB' => CurrencyCode.rub,
      _ => null,
    };
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd-$mm-$yyyy';
  }

  Future<FxRateSnapshot?> _fetchByCandidates({
    required String quoteCode,
    required FxRateKind kind,
    required List<String> buySeriesCandidates,
    required List<String> sellSeriesCandidates,
  }) async {
    for (var i = 0; i < buySeriesCandidates.length; i++) {
      final buyCode = buySeriesCandidates[i];
      final sellCode = sellSeriesCandidates[i];
      final quote = await _fetchFromSeries(
        series: '$buyCode-$sellCode',
        quoteCode: quoteCode,
      );
      if (quote == null) continue;
      return FxRateSnapshot(
        currency: quote.quote,
        kind: kind,
        buy: quote.buy,
        sell: quote.sell,
        timestamp: quote.timestamp,
        source: quote.source,
        status: quote.status,
      );
    }
    return null;
  }

  Future<ExchangeRateQuote?> _fetchFromSeries({
    required String series,
    required String quoteCode,
  }) async {
    for (final baseUrl in _baseUrls) {
      final result = await _tryFetch(
        baseUrl: baseUrl,
        series: series,
        quoteCode: quoteCode,
      );
      if (result != null) return result;
    }
    return null;
  }
}
