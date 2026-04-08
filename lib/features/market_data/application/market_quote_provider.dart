import 'package:flutter_riverpod/flutter_riverpod.dart';

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
