import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../app/flavor/app_flavor.dart';
import '../../../core/types/decimal_value.dart';
import '../../../core/types/currency_code.dart';
import '../data/in_memory_market_repository.dart';
import '../data/tcmb_evds_repository.dart';
import '../domain/market_models.dart';
import 'quote_fallback_service.dart';
import '../../settings/application/display_settings_controller.dart';
import '../../settings/domain/display_settings.dart';

final tcmbApiKeyProvider = Provider<String>((ref) {
  return const String.fromEnvironment('TCMB_API_KEY', defaultValue: '');
});

final marketQuoteServiceProvider = Provider<QuoteFallbackService>((ref) {
  final providers = <dynamic>[];

  if (AppFlavor.enableLiveMarketProviders) {
    final apiKey = ref.watch(tcmbApiKeyProvider);
    providers.add(TcmbEvdsRepository(apiKey: apiKey));
  }

  providers.add(
    InMemoryMarketRepository(
      source: DataSourceType.cache,
      seed: DecimalValue.parse('38.25'),
    ),
  );

  return QuoteFallbackService(providers.cast());
});

final tryUsdQuoteProvider = FutureProvider<ExchangeRateQuote?>((ref) async {
  final service = ref.watch(marketQuoteServiceProvider);
  return service.resolve('TRY', 'USD');
});

final trackedFxRatesProvider = FutureProvider<List<FxRateSnapshot>>((
  ref,
) async {
  final items = <FxRateSnapshot>[];
  final apiKey = ref.watch(tcmbApiKeyProvider);

  if (AppFlavor.enableLiveMarketProviders && apiKey.trim().isNotEmpty) {
    final tcmb = TcmbEvdsRepository(apiKey: apiKey);
    final live = await tcmb.getTrackedFxRates();
    items.addAll(live);
  }

  if (items.isEmpty) {
    final now = DateTime.now();
    items.addAll([
      FxRateSnapshot(
        currency: CurrencyCode.usd,
        kind: FxRateKind.daily,
        buy: DecimalValue.parse('38.2500'),
        sell: DecimalValue.parse('38.3000'),
        timestamp: now,
        source: DataSourceType.cache,
        status: MarketDataStatus.stale,
      ),
      FxRateSnapshot(
        currency: CurrencyCode.usd,
        kind: FxRateKind.effective,
        buy: DecimalValue.parse('38.2200'),
        sell: DecimalValue.parse('38.3400'),
        timestamp: now,
        source: DataSourceType.cache,
        status: MarketDataStatus.stale,
      ),
      FxRateSnapshot(
        currency: CurrencyCode.eur,
        kind: FxRateKind.daily,
        buy: DecimalValue.parse('41.1200'),
        sell: DecimalValue.parse('41.2000'),
        timestamp: now,
        source: DataSourceType.cache,
        status: MarketDataStatus.stale,
      ),
      FxRateSnapshot(
        currency: CurrencyCode.eur,
        kind: FxRateKind.effective,
        buy: DecimalValue.parse('41.0900'),
        sell: DecimalValue.parse('41.2400'),
        timestamp: now,
        source: DataSourceType.cache,
        status: MarketDataStatus.stale,
      ),
      FxRateSnapshot(
        currency: CurrencyCode.gbp,
        kind: FxRateKind.daily,
        buy: DecimalValue.parse('48.0500'),
        sell: DecimalValue.parse('48.2000'),
        timestamp: now,
        source: DataSourceType.cache,
        status: MarketDataStatus.stale,
      ),
      FxRateSnapshot(
        currency: CurrencyCode.gbp,
        kind: FxRateKind.effective,
        buy: DecimalValue.parse('48.0000'),
        sell: DecimalValue.parse('48.2700'),
        timestamp: now,
        source: DataSourceType.cache,
        status: MarketDataStatus.stale,
      ),
    ]);
  }

  return items;
});

final trackedMarketWatchProvider = FutureProvider<List<MarketWatchSnapshot>>((
  ref,
) async {
  final now = DateTime.now();
  final fx = await ref.watch(trackedFxRatesProvider.future);
  final settings = ref.watch(displaySettingsProvider);
  final usdTry = _resolveUsdTry(fx);
  final stockRows = await _fetchStocksAuto(
    symbols: settings.marketStockSymbols,
  );
  if (usdTry != null) {
    final live = await _fetchMarketWatchFromYahoo(usdTry: usdTry, now: now);
    if (live.isNotEmpty) return [...live, ...stockRows];
  }

  return [..._fallbackMarketWatch(now), ...stockRows];
});

Future<List<MarketWatchSnapshot>> _fetchMarketWatchFromYahoo({
  required DecimalValue usdTry,
  required DateTime now,
}) async {
  const symbolQuery = 'BTC-USD,ETH-USD,BZ=F,GC=F';
  final uri = Uri.parse(
    'https://query1.finance.yahoo.com/v7/finance/quote?symbols=$symbolQuery',
  );
  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) return const [];
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return const [];
    final quoteResponse = body['quoteResponse'];
    if (quoteResponse is! Map<String, dynamic>) return const [];
    final results = quoteResponse['result'];
    if (results is! List) return const [];

    final bySymbol = <String, double>{};
    for (final item in results) {
      if (item is! Map) continue;
      final symbol = item['symbol']?.toString();
      final price = (item['regularMarketPrice'] as num?)?.toDouble();
      if (symbol == null || price == null) continue;
      bySymbol[symbol] = price;
    }

    final usdTryDouble = double.tryParse(usdTry.toString());
    if (usdTryDouble == null) return const [];

    final btc = bySymbol['BTC-USD'];
    final eth = bySymbol['ETH-USD'];
    final brent = bySymbol['BZ=F'];
    final xau = bySymbol['GC=F'];
    if (btc == null || eth == null || brent == null || xau == null) {
      return const [];
    }

    final gramGoldTry = (xau * usdTryDouble) / 31.1034768;
    final quarterGoldTry = gramGoldTry * 1.754;

    DecimalValue asDecimal(double value) =>
        DecimalValue.parse(value.toStringAsFixed(8));

    return [
      MarketWatchSnapshot(
        code: 'BTC',
        name: 'Bitcoin',
        kind: MarketWatchKind.crypto,
        priceTry: asDecimal(btc),
        unit: 'USD',
        timestamp: now,
        source: DataSourceType.apiFallback,
        status: MarketDataStatus.live,
      ),
      MarketWatchSnapshot(
        code: 'ETH',
        name: 'Ethereum',
        kind: MarketWatchKind.crypto,
        priceTry: asDecimal(eth),
        unit: 'USD',
        timestamp: now,
        source: DataSourceType.apiFallback,
        status: MarketDataStatus.live,
      ),
      MarketWatchSnapshot(
        code: 'XAU_GR',
        name: 'Gram Altın',
        kind: MarketWatchKind.preciousMetal,
        priceTry: asDecimal(gramGoldTry),
        unit: 'TRY/gr',
        timestamp: now,
        source: DataSourceType.apiFallback,
        status: MarketDataStatus.live,
      ),
      MarketWatchSnapshot(
        code: 'CEYREK',
        name: 'Çeyrek Altın',
        kind: MarketWatchKind.preciousMetal,
        priceTry: asDecimal(quarterGoldTry),
        unit: 'TRY',
        timestamp: now,
        source: DataSourceType.apiFallback,
        status: MarketDataStatus.live,
      ),
      MarketWatchSnapshot(
        code: 'BRENT',
        name: 'Brent Petrol',
        kind: MarketWatchKind.energy,
        priceTry: asDecimal(brent),
        unit: 'USD',
        timestamp: now,
        source: DataSourceType.apiFallback,
        status: MarketDataStatus.live,
      ),
    ];
  } catch (_) {
    return const [];
  }
}

Future<List<MarketWatchSnapshot>> _fetchStocksAuto({
  required List<String> symbols,
}) async {
  final rows = <MarketWatchSnapshot>[];
  for (final symbol in symbols.take(maxMarketStockSymbols)) {
    final code = symbol.trim().toUpperCase();
    if (code.isEmpty) continue;
    final item =
        await _fetchStockFromBigpara(code) ?? await _fetchStockFromYahoo(code);
    if (item != null) {
      rows.add(item);
    }
  }
  return rows;
}

Future<MarketWatchSnapshot?> _fetchStockFromBigpara(String rawCode) async {
  final code = rawCode.replaceAll('.IS', '');
  final uri = Uri.parse(
    'https://bigpara.hurriyet.com.tr/api/v1/borsa/hisseyuzeysel/$code',
  );
  try {
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    if (body['code']?.toString() != '0') return null;
    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;
    final stock = data['hisseYuzeysel'];
    if (stock is! Map<String, dynamic>) return null;

    DecimalValue? pick(String key) {
      final value = stock[key];
      if (value == null) return null;
      try {
        return DecimalValue.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final timestamp =
        DateTime.tryParse(stock['tarih']?.toString() ?? '') ?? DateTime.now();
    final sell = pick('satis') ?? pick('kapanis') ?? pick('alis');
    if (sell == null) return null;

    return MarketWatchSnapshot(
      code: stock['sembol']?.toString() ?? code,
      name: stock['aciklama']?.toString() ?? '$code Hisse',
      kind: MarketWatchKind.stock,
      priceTry: sell,
      openTry: pick('acilis') ?? pick('alis'),
      closeTry: pick('kapanis') ?? pick('dunkukapanis') ?? sell,
      lowTry: pick('dusuk'),
      highTry: pick('yuksek'),
      unit: 'TRY',
      timestamp: timestamp,
      source: DataSourceType.apiFallback,
      status: MarketDataStatus.live,
    );
  } catch (_) {
    return null;
  }
}

Future<MarketWatchSnapshot?> _fetchStockFromYahoo(String rawCode) async {
  final normalized = rawCode.trim().toUpperCase().replaceAll('.IS', '');
  if (normalized.isEmpty) return null;
  final uri = Uri.parse(
    'https://api.nasdaq.com/api/quote/$normalized/info?assetclass=stocks',
  );
  try {
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    final data = body['data'];
    if (data is! Map<String, dynamic>) return null;
    final primary = data['primaryData'];
    final secondary = data['secondaryData'];
    if (primary is! Map<String, dynamic>) return null;

    DecimalValue? parseMoney(dynamic raw) {
      if (raw == null) return null;
      final cleaned = raw
          .toString()
          .replaceAll('\$', '')
          .replaceAll(',', '')
          .replaceAll('%', '')
          .trim();
      if (cleaned.isEmpty || cleaned == 'NA') return null;
      try {
        return DecimalValue.parse(cleaned);
      } catch (_) {
        return null;
      }
    }

    final price =
        parseMoney(primary['lastSalePrice']) ??
        parseMoney(secondary?['lastSalePrice']);
    if (price == null) return null;

    return MarketWatchSnapshot(
      code: data['symbol']?.toString() ?? normalized,
      name: data['companyName']?.toString() ?? normalized,
      kind: MarketWatchKind.stock,
      priceTry: price,
      openTry: null,
      closeTry: parseMoney(secondary?['lastSalePrice']) ?? price,
      lowTry: null,
      highTry: null,
      unit: 'USD',
      timestamp: DateTime.now(),
      source: DataSourceType.apiFallback,
      status: MarketDataStatus.live,
    );
  } catch (_) {
    return null;
  }
}

Future<List<MarketHistoryPoint>> fetchStockHistory(
  String code, {
  DateTime? startDate,
}) async {
  final normalized = code.trim().toUpperCase().replaceAll('.IS', '');
  final nasdaqUri = Uri.parse(
    'https://api.nasdaq.com/api/quote/$normalized/chart?assetclass=stocks',
  );
  try {
    final response = await http.get(
      nasdaqUri,
      headers: const {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          final chart = data['chart'];
          if (chart is List && chart.isNotEmpty) {
            final points = <MarketHistoryPoint>[];
            for (final entry in chart) {
              if (entry is! Map) continue;
              final x = (entry['x'] as num?)?.toInt();
              final y = (entry['y'] as num?)?.toDouble();
              if (x == null || y == null) continue;
              points.add(
                MarketHistoryPoint(
                  time: DateTime.fromMillisecondsSinceEpoch(x),
                  value: DecimalValue.parse(y.toString()),
                  label: entry['z'] is Map
                      ? entry['z']['dateTime']?.toString()
                      : null,
                ),
              );
            }
            if (points.isNotEmpty) {
              final filtered = _filterHistory(points, startDate: startDate);
              return filtered.isNotEmpty ? filtered : points;
            }
          }
        }
      }
    }
  } catch (_) {}

  final bist = await _fetchStockFromBigpara(normalized);
  if (bist == null) return const [];
  final close = bist.closeTry ?? bist.priceTry;
  final open = bist.openTry ?? close;
  final low = bist.lowTry ?? close;
  final high = bist.highTry ?? close;
  final now = bist.timestamp;
  final fallback = [
    MarketHistoryPoint(
      time: now.subtract(const Duration(hours: 3)),
      value: open,
      label: 'Acilis',
    ),
    MarketHistoryPoint(
      time: now.subtract(const Duration(hours: 2)),
      value: low,
      label: 'Dusuk',
    ),
    MarketHistoryPoint(
      time: now.subtract(const Duration(hours: 1)),
      value: high,
      label: 'Yuksek',
    ),
    MarketHistoryPoint(time: now, value: close, label: 'Kapanis'),
  ];
  return _filterHistory(fallback, startDate: startDate);
}

List<MarketHistoryPoint> _filterHistory(
  List<MarketHistoryPoint> points, {
  DateTime? startDate,
}) {
  if (startDate == null) return points;
  final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
  final now = DateTime.now();
  return points
      .where(
        (point) =>
            !point.time.isBefore(normalizedStart) && !point.time.isAfter(now),
      )
      .toList();
}

DecimalValue? _resolveUsdTry(List<FxRateSnapshot> fx) {
  for (final e in fx) {
    if (e.currency == CurrencyCode.usd && e.kind == FxRateKind.effective) {
      return e.sell;
    }
  }
  for (final e in fx) {
    if (e.currency == CurrencyCode.usd && e.kind == FxRateKind.daily) {
      return e.sell;
    }
  }
  return null;
}

List<MarketWatchSnapshot> _fallbackMarketWatch(DateTime now) => [
  MarketWatchSnapshot(
    code: 'BTC',
    name: 'Bitcoin',
    kind: MarketWatchKind.crypto,
    priceTry: DecimalValue.parse('69450'),
    unit: 'USD',
    timestamp: now,
    source: DataSourceType.cache,
    status: MarketDataStatus.stale,
  ),
  MarketWatchSnapshot(
    code: 'ETH',
    name: 'Ethereum',
    kind: MarketWatchKind.crypto,
    priceTry: DecimalValue.parse('3650'),
    unit: 'USD',
    timestamp: now,
    source: DataSourceType.cache,
    status: MarketDataStatus.stale,
  ),
  MarketWatchSnapshot(
    code: 'XAU_GR',
    name: 'Gram Altın',
    kind: MarketWatchKind.preciousMetal,
    priceTry: DecimalValue.parse('3825'),
    unit: 'TRY/gr',
    timestamp: now,
    source: DataSourceType.cache,
    status: MarketDataStatus.stale,
  ),
  MarketWatchSnapshot(
    code: 'CEYREK',
    name: 'Çeyrek Altın',
    kind: MarketWatchKind.preciousMetal,
    priceTry: DecimalValue.parse('6720'),
    unit: 'TRY',
    timestamp: now,
    source: DataSourceType.cache,
    status: MarketDataStatus.stale,
  ),
  MarketWatchSnapshot(
    code: 'BRENT',
    name: 'Brent Petrol',
    kind: MarketWatchKind.energy,
    priceTry: DecimalValue.parse('98.4'),
    unit: 'USD',
    timestamp: now,
    source: DataSourceType.cache,
    status: MarketDataStatus.stale,
  ),
];
