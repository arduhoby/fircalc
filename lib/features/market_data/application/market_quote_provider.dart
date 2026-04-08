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
  final usdTry = _resolveUsdTry(fx);
  if (usdTry != null) {
    final live = await _fetchMarketWatchFromYahoo(usdTry: usdTry, now: now);
    if (live.isNotEmpty) return live;
  }

  return _fallbackMarketWatch(now);
});

Future<List<MarketWatchSnapshot>> _fetchMarketWatchFromYahoo({
  required DecimalValue usdTry,
  required DateTime now,
}) async {
  final uri = Uri.parse(
    'https://query1.finance.yahoo.com/v7/finance/quote?symbols=BTC-USD,ETH-USD,BZ=F,GC=F',
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
        priceTry: asDecimal(btc * usdTryDouble),
        unit: 'TRY',
        timestamp: now,
        source: DataSourceType.apiFallback,
        status: MarketDataStatus.live,
      ),
      MarketWatchSnapshot(
        code: 'ETH',
        name: 'Ethereum',
        kind: MarketWatchKind.crypto,
        priceTry: asDecimal(eth * usdTryDouble),
        unit: 'TRY',
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
        code: 'ALT_CEYREK',
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
        priceTry: asDecimal(brent * usdTryDouble),
        unit: 'TRY/varil',
        timestamp: now,
        source: DataSourceType.apiFallback,
        status: MarketDataStatus.live,
      ),
    ];
  } catch (_) {
    return const [];
  }
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
    priceTry: DecimalValue.parse('2665000'),
    unit: 'TRY',
    timestamp: now,
    source: DataSourceType.cache,
    status: MarketDataStatus.stale,
  ),
  MarketWatchSnapshot(
    code: 'ETH',
    name: 'Ethereum',
    kind: MarketWatchKind.crypto,
    priceTry: DecimalValue.parse('129000'),
    unit: 'TRY',
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
    code: 'ALT_CEYREK',
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
    priceTry: DecimalValue.parse('3450'),
    unit: 'TRY/varil',
    timestamp: now,
    source: DataSourceType.cache,
    status: MarketDataStatus.stale,
  ),
];
